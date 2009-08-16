
require 'jiji/util/util'
require "jiji/dao/timed_data_dao"
require 'yaml'
require 'jiji/util/fix_yaml_bug'
require 'jiji/util/file_lock'
require 'fileutils'

module JIJI

  # Outputのマネージャ
  class OutputManager

    #コンストラクタ
    #registry:: レジストリ
    def initialize( registry )
      @registry = registry
    end

    #指定されたプロセスのOutputを列挙する
    #process_id:: プロセスID
    def each( process_id )
      map = get_process_map( process_id )
      map.each_pair {|k,v|
        yield v
      }
    end

    #指定されたプロセスの指定エージェントのOutputを生成する
    #すでに作成済みであればそれをそのまま返す。
    #process_id:: プロセスID
    #agent_id:: エージェントID
    def create( process_id, agent_id )
      map = get_process_map( process_id )
      unless map.key?( agent_id )
        map[agent_id] = @registry.output( process_id, agent_id )
      end
      return map[agent_id]
    end

    #指定されたプロセスの指定エージェントのOutputを取得する
    #process_id:: プロセスID
    #agent_id:: エージェントID
    def get( process_id, agent_id )
      map = get_process_map( process_id )
      unless map.key?( agent_id )
        raise UserError.new( JIJI::ERROR_NOT_FOUND, "agent not found. id=#{agent_id}")
      end
      return map[agent_id]
    end

    #指定されたプロセスの指定エージェントのOutputを削除する
    #process_id:: プロセスID
    #agent_id:: エージェントID
    def delete( process_id, agent_id )
      map = get_process_map( process_id )
      unless map.key?( agent_id )
        raise UserError.new( JIJI::ERROR_NOT_FOUND, "agent not found. id=#{agent_id}")
      end
      FileUtils.rm_rf "#{@registry.output_dir(process_id)}/#{agent_id}"
      map.delete(agent_id)
    end

    # 指定のプロセスに対応するoutputを取得する。
    def get_process_map( process_id )
     load_output( process_id )
    end

  private
    def load_output( process_id )
      # 既存データの読み込み
      map = {}
      dir = @registry.output_dir(process_id)
      Dir.glob( "#{dir}/*" ) {|d|
        properties_file = "#{d}/#{JIJI::Output::PROPERTIES_FILE_NAME}"
        next unless File.directory? d
        next unless File.exist? properties_file
        agent_id = File.basename( d )
        map[agent_id] = @registry.output( process_id, agent_id )
      }
      map
    end
  end
end