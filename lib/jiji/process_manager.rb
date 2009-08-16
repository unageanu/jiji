
require 'uuidtools'
require 'yaml'
require 'jiji/util/fix_yaml_bug'

module JIJI
  class ProcessManager

    include Enumerable

    def initialize( registry )
      @registry = registry
      @executor = registry.back_test_process_executor
      @rmt = @registry.rmt_process
      @back_tests = {}
      @logger = registry.server_logger

      # 既存のバックテスト一覧を読み込む
      Dir.glob( "#{registry.process_dir}/*" ) {|d|
        next unless File.directory? d
        next unless File.exist? "#{d}/#{JIJI::ProcessInfo::PROPERTY_FILE}"
        begin
          id = File.basename(d)
          next if id == "rmt"
          info = @registry.process_info( id )
          process = @registry.process_info(id)
          process.load # 保存しておいた設定情報をロード
          @back_tests[id] = process
        rescue
          @logger.error $!
        end
      }
    end

    # RMTプロセスをスタートする
    def start
      if @conf.get([:collector,:collect], true )
        begin
          @rmt.load_agents( true )
          @rmt.start
        rescue
          @rmt.logger.error $!
        end
      end
    end

    # すべてのプロセスを停止する
    def stop
      @stoped = true
      @registry.operator( "rmt", false, nil).stop
      @rmt.stop
      @executor.stop
    end

    # バックテストプロセスを列挙する
    def each( &block )
      @back_tests.each_pair {|k,v|
        yield v
      }
    end

    # プロセスを取得する
    def get( id )
      unless id == "rmt" || @back_tests.key?(id)
        raise UserError.new( JIJI::ERROR_NOT_FOUND, "process not found")
      end
      id == "rmt" ? @rmt.info : @back_tests[id]
    end

    # プロセスの設定を更新する。
    def set( process_id, setting )
      p = get( process_id )
      failed = {}
      setting.each_pair {|k,v|
        case k
          when "trade_enable"
            # バックテストの変更は許可しない。
            unless  process_id == "rmt"
              raise UserError.new( JIJI::ERROR_ILLEGAL_ARGUMENTS, "illegal id.id=#{process_id}" )
            end
            value = ( v == "true" || v == true )
            @rmt.trade_enable = value
            @rmt.info["trade_enable"] = value
          when "agents"
            p = get( process_id )
            if ( process_id == "rmt" )
              failed = @rmt.set_agents(v)
            else
              failed = @executor.set_agents(process_id, v)
            end
            p["agents"] = create_success_agent_setting( p["agents"], v, failed )
        end
      }
      failed
    end

    # バックテストプロセスを新規に作成する
    def create_back_test( name, memo, start_date, end_date, agent_properties )
      id = UUIDTools::UUID.random_create().to_s

      # プロパティを記録
      props = {
        "id"=>id,
        "name"=>name,
        "memo"=>memo,
        "create_date"=>Time.now.to_i,
        "start_date"=>start_date.to_i,
        "end_date"=>end_date.to_i,
        "agents"=>agent_properties,
        "state"=>:WAITING
      }
      return start_process( id, props )
    end

    # バックテストプロセスを再起動する
    def restart_test( id, agent_properties=nil )
      unless id == "rmt" || @back_tests.key?(id)
        raise UserError.new( JIJI::ERROR_NOT_FOUND, "process not found")
      end
      p = get(id)
      new_id = UUIDTools::UUID.random_create().to_s # 別のIDを再割り当てする。
      props = {
        "id"=>new_id,
        "name"=>p["name"],
        "memo"=>p["memo"],
        "create_date"=>Time.now.to_i,
        "start_date"=>p["start_date"],
        "end_date"=>p["end_date"],
        "agents"=>agent_properties || p["agents"],
        "state"=>:WAITING
      }
      result = start_process( new_id, props )
      delete_back_test( id )
      return result
    end

    # バックテストプロセスを削除する
    # ログファイルもすべて削除。
    def delete_back_test( id )
      unless id == "rmt" || @back_tests.key?(id)
        raise UserError.new( JIJI::ERROR_NOT_FOUND, "process not found")
      end
      @executor.delete(id)
      @back_tests.delete( id )
      FileUtils.rm_rf "#{@registry.process_dir}/#{id}"
    end

    attr :registry, true
    attr :conf, true
    attr :executor, true
    attr :rmt, true

  private
    # バックテストを開始する
    def start_process( id, props )
      info = @registry.process_info( id )
      info.props = props
      @executor << info
      @back_tests[id] = info
      return {
       "id"=>id,
       "name"=>props["name"],
       "create_date"=>props["create_date"]
      }
    end

    #更新に成功したエージェントの設定情報を作成する
    def create_success_agent_setting( current, new_agents, failed )
      failed.each {|pair|
        case pair[1][:operation]
          #新規作成で失敗したものは除外
          when :add
            new_agents = new_agents.reject {|i| i["id"] == pair[0]}
          #更新、削除で失敗したものは現在の設定をそのままキープする
          when :update
            new_agents = new_agents.map {|i| 
               i["id"] != pair[0] ? i : current.find {|j| j["id"] == pair[0] }
            }
          when :remove
            new_agents << current.find {|j| j["id"] == pair[0] }
        end
      }
      return new_agents
    end
  end

  class BackTestProcessExecutor

    def initialize
      @running = nil
      @mutex = Mutex.new
      @waiting = []
    end

    #実行対象とするプロセスを追加する
    def <<(info)
      begin
        btp = @registry.backtest_process(info )
        btp.load_agents( false )
        @mutex.synchronize {
          if @running == nil
            @running = btp
            @running.collector.listeners << self
            @running.start
          else
            @waiting << btp
          end
        }
      rescue Exception
        begin
          btp.stop if btp
        rescue Exception
        ensure
          FileUtils.rm_rf "#{@process_dir}/#{info.process_id}"
        end
        raise $!
      end
    end

    #全てのプロセスの実行を停止する
    def stop
      @mutex.synchronize {
        @waiting.each {|i|
          i.collector.listeners.delete(self)
          i.stop
        }
        @waiting.clear
        if @running != nil
          @running.collector.listeners.delete(self)
          @running.stop
          @running = nil
        end
      }
    end

    #プロセスを削除する
    def delete(id)
      @mutex.synchronize {
        if @running != nil && @running.info.process_id == id
          #実行中であれば停止して次に
          @running.collector.listeners.delete(self)
          @running.stop
          run_next
        else
          # 待機中であればキューから除外。
          @waiting = @waiting.reject{|i| i.info.process_id == id }
        end
      }
    end

    #エージエントの設定を更新する
    def set_agents(id, agents)
      @mutex.synchronize {
        p = get(id)
        p ? p.set_agents(agents) : {}
      }
    end

    #idに対応するプロセスがあれば取得する
    def get(id)
      if @running != nil && @running.info.process_id == id
        return @running
      else
        return @waiting.find{|p|p.info.process_id == id}
      end
    end

    #プロセスの実行終了通知を受け取る
    def on_finished(state, time)
      @mutex.synchronize {
        run_next
      }
    end

    attr :registry, true

  private
    #待ち中のプロセスがあれば実行を開始する。
    def run_next
      unless @waiting.empty?
        @running = @waiting.shift
        @running.collector.listeners << self
        @running.start
      else
        @running = nil
      end
    end
  end

end