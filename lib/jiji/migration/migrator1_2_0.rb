
require 'fileutils'
require 'yaml'
require 'jiji/util/fix_yaml_bug'
require 'jiji/util/file_lock'
require 'jiji/process'
require 'kconv'

module JIJI
  module Migration

    #===1.1.3 → 1.2.0
    class Migrator1_2_0
      def migrate( registry )
        logger = registry.server_logger

        #出力の保存先を置換
        Dir.glob("#{registry.process_dir}/*") {|d|
          
          logger.info "convert : #{d}"
          process_id = File.basename(d)
          process_info = {}
          begin
            file = "#{d}/#{JIJI::ProcessInfo::PROPERTY_FILE}"
            process_info = YAML.load_file(file) if  File.exist?(file)
          rescue Exception
            logger.error $!
          end
          
          begin
            # 出力データを列挙
            Dir.glob("#{d}/out/*").map.each {|out_dir|
              convert_out_dir( out_dir, process_info, logger )
            }
          rescue Exception
            logger.error $!
          end
        }
      end

      #各出力ディリクトリデータのリネーム
      def convert_out_dir( out_dir, info, logger )
        begin
          agent_id = JIJI::Util.decode( File.basename(out_dir))
          agent_name = resolve_name( info, agent_id )
          FileLock.new( "#{out_dir}/#{JIJI::Output::PROPERTIES_FILE_NAME}" ).writelock { |f|
            f.write( YAML.dump({:agent_name=>agent_name}) )
          }
          FileUtils.mv out_dir, "#{File.dirname(out_dir)}/#{agent_id}"
        rescue Exception
          logger.error $!
        end
      end
      #エージェント名を解決する
      def resolve_name( process_info, agent_id )
        if ( process_info["agents"]  )
          item = process_info["agents"].find {|i| i["id"] == agent_id }
          return item["name"] if item
        end
        return "不明"
      end

    end

  end
end

