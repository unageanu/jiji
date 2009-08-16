
require 'jiji/agent/agent'
require 'jiji/agent/agent_manager'
require 'jiji/agent/agent_registry'
require 'jiji/agent/permitter'
require 'jiji/agent/util'
require 'jiji/util/file_lock'
require 'set'
require "thread"

module JIJI

  # プロセス
  class Process

    # コンストラクタ
    def initialize( info )
      @info = info
      @started_mutex = Mutex.new
      @started_mutex.synchronize {
        @started= false
      }
    end

    #エージェントをロードする
    def load_agents( ignore_error )
      info.load_agents( agent_manager,
        agent_manager.agent_registry, logger, ignore_error )
    end

    def start
      @started_mutex.synchronize {
        @started= true
        collector.listeners << self
        collector.start
      }
      # 状態を覚えておく
      info["state"] = collector.state
    end

    def stop
      @started_mutex.synchronize {
        if @started  # 起動していない場合は何もしない
          observer_manager.stop
          collector.stop

          # 状態を覚えておく
          info["state"] = collector.state
          @started = false
        else
          # 待機中の場合、キャンセル状態にする。
          if info["state"] == :WAITING
           info["state"] = :CANCELED
         end
         logger.close if logger
         @logger = nil
        end
      }
    end

    #自動取引のon/offを設定する
    def trade_enable=(enable)
      agent_manager.operator.trade_enable = enable
    end

    #エージェントの設定を更新する
    #戻り値:: 変更に失敗したエージェントの一覧
    def set_agents(agents)
      failed = {}
      # エージェントの設定が更新された
      # 削除対象を特定するため、登録済みエージェントのIDのセットを作成
      set = info["agents"] ? info["agents"].inject({}){|s,i| s[i["id"]]=i;s} : {}
      agents.each {|item|
        # プロパティの更新 / 対応するエージェントが存在しなければ作成。
        set_agent_properties( item, agent_manager, failed )
        set.delete item["id"]
      }
      # Mapに含まれていないエージェントは削除
      set.each { |pair|
        info = pair[1]
        begin
          logger.info "remove agent. name=#{info["name"]} id=#{info["id"]}"
          agent_manager.remove( info["id"] )
        rescue Exception
          logger.warn "failed to remove agent. name=#{info["name"]} id=#{info["id"]}"
          logger.warn $!
          failed[info["id"]] = {:cause=>$!.to_s,:info=>info,:operation=>:remove}
        end
      }
      failed
    end

    # コレクターの終了通知を受け取る
    def on_finished( state, now )
      begin
        info["state"] = state
        agent_manager.flush( now )
      ensure
         logger.close if logger
         @logger = nil
      end
    end

    # コレクターからの進捗通知を受け取る
    def on_progress_changed( progress )
      info.progress = progress
    end

    attr :info, true
    attr :collector, true
    attr :observer_manager, true
    attr :agent_manager, true
    attr :logger, true

  private
    # 任意のエージェントの設定を更新する。
    # エージェントは初期化されない。propertiesのみ変更される。
    def set_agent_properties( item, agent_manager, failed )
      id, name, props, cl = item["id"], item["name"], item["properties"], item["class"]
      a = agent_manager.get(id)
      begin
        if a
          logger.info "update agent. name=#{name} id=#{id}"
          a.agent.properties = props
          if name
            a.output.agent_name = name
            a.operator.agent_name = name
          end
        else
          logger.info "add agent. name=#{name} id=#{id}"
          agent = agent_manager.agent_registry.create( cl, props )
          agent_manager.add( id, agent, name )
        end
      rescue Exception
        logger.warn " failed to create or update agent. name=#{name} id=#{id}"
        logger.warn $!
        failed[id] = {:cause=>$!.to_s,:info=>item, :operation=> a ? :update : :add}
      end
    end
  end

  # プロセス情報
  class ProcessInfo

    PROPERTY_FILE = "props.yaml"

    # コンストラクタ
    def initialize( process_id, process_dir )
      @process_id = process_id
      @process_dir = process_dir
      FileUtils.mkdir_p dir
      @progress = 0
      @props = {}
    end

    #データが存在するか評価する
    def data_exist?
      File.exist? prop_file
    end

    # 設定を保存する
    def save
      file = prop_file
      lock {
        File.open( file, "w" ) { |f|
          f.write( YAML.dump(@props) )
        }
      }
    end

    # 設定をロードする
    def load
      # 保存したファイルがあれば、ファイルから設定値を読み込む
      file = prop_file
      lock {
        if ( File.exist? file )
          @props = YAML.load_file file
        end
      }
    end

    def []=(k,v)
      @props[k] = v
      save
    end
    def [](k)
      @props[k]
    end
    def props=(props)
      @props = props
      save
    end

    #設定情報を元にエージェントを作成し、agent_managerに登録する
    #agent_manager:: エージェントマネージャ
    #agent_registry:: エージェントレジストリ
    #logger:: エージェントのロードでエラーになった場合のログの出力先
    #ignore_error:: ロードエラーを例外として通知するかどうか。通知しない場合true
    def load_agents( agent_manager, agent_registry, logger, ignore_error=false )
      agent_manager.clear
      return if !@props || !@props.key?("agents")
      @props["agents"].each {|v|
        begin
          agent = agent_registry.create( v["class"], v["properties"] )
          agent_manager.add( v["id"], agent, v["name"] )
        rescue Exception
          logger.warn " failed to create agent. name=#{v["name"]} id=#{v["id"]}"
          logger.warn $!
          raise $! unless ignore_error
        end
      }
    end

    #ID
    attr :process_id, true
    #プロパティ
    attr_reader :props
    #進捗状況
    attr :progress, true

  private
    def prop_file
      "#{dir}/#{PROPERTY_FILE}"
    end
    def dir
      "#{@process_dir}/#{@process_id}"
    end
    def lock
      DirLock.new( dir ).writelock {
        yield
      }
    end
  end
end