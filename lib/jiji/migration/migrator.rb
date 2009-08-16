
require 'rubygems'
require 'fileutils'
require 'logger'
require 'jiji/util/file_lock'

module JIJI
  module Migration
    
    #==サーバー起動時にデータ移行を行うクラス。
    class Migrator

      #データを移行する。
      def migrate
        logger = server_logger
        begin
          data_version = version
          new_version = data_version
          tmp = nil
          @migrators.sort_by {|item| item[:version] }.each {|d|
            tmp = d[:version]
            if ( data_version < d[:version] )
              d[:migrator].migrate(registry)
              new_version = d[:version]
              logger.info "data migration succesful! new_version=#{new_version.to_s}."
            end
          }
        rescue Exception
          logger.error "data migration failed. current=#{data_version.to_s} new_version=#{tmp.to_s}"
          logger.error $!
        ensure
          FileLock.new( version_file ).writelock {|f| f << new_version.to_s }
        end
      end
      
      # 現在のデータバージョンを取得する。
      def version
        version_str = File.exist?(version_file) ? 
          FileLock.new( version_file ).readlock {|f| f.read } : "1.0.0"
        return Gem::Version.new( version_str )
      end
      
      attr :migrators, true
      attr :server_logger, true
      attr :version_file, true
      attr :registry, true
    end
  end
end

