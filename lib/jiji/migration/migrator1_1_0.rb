
require 'fileutils'
require 'yaml'
require 'jiji/util/fix_yaml_bug'
require 'jiji/util/file_lock'

module JIJI
  module Migration

    #===1.0.3 → 1.1.0
    class Migrator1_1_0
      def migrate( registry )
        #設定ファイルを更新
        conf_file = registry.base_dir + "/conf/configuration.yaml"
        return unless File.exist? conf_file
        tmp = key_to_sym(YAML.load_file(conf_file))
        
        # 証券会社アクセス関連の設定値を置換
        if( tmp[:securities] && tmp[:securities][:account]  ) 
          old = tmp[:securities]
          tmp[:securities] = {
            :type=>:click_securities_demo,
            :user=>old[:account] &&old[:account][:user] ? old[:account][:user] : "",
            :password=>old[:account] &&old[:account][:password] ? old[:account][:password] : ""
          }
          open( conf_file, "w" ) {|f|
            f << YAML.dump( tmp )
          }
          # 設定値を再読み込み
          registry.conf.load
        end
      end
      
      # ハッシュのキーをシンボルに置換する
      def key_to_sym( map )
        map.inject({}) {|r,e|
           v = e[1].kind_of?(Hash) ? key_to_sym( e[1] ) : e[1]
           r.store(e[0].to_sym, v)
           r
        }
      end
    end
    
  end
end

