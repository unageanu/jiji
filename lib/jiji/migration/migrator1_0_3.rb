
require 'fileutils'
require 'yaml'
require 'jiji/util/fix_yaml_bug'
require 'jiji/util/file_lock'

module JIJI
  module Migration

    #===1.0.0 → 1.0.3
    class Migrator1_0_3
      def migrate( registry )
        # outputのプロパティキーを変換
        Dir.glob( "#{registry.process_dir}/*/out/**/meta.yaml").each {|meta|
          props = YAML.load_file meta
          props = props.inject({}) {|r,p| r[p[0].to_sym] = p[1]; r }
          FileLock.new( meta ).writelock { |f|
            f.write( YAML.dump( props ) )
          }
        }
      end
    end
    
  end
end

