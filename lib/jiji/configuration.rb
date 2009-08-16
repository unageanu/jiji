
require 'jiji/util/fix_yaml_bug'
require 'jiji/util/file_lock'

module JIJI

  #
  #==設定値
  #
  class Configuration

    #コンストラクタ
    #configuration_file:: 設定ファイルのパス
    def initialize( configuration_file=nil )
      @configuration_file=configuration_file
      load
    end
    
    # データをロードする
    def load
      if @configuration_file && File.exist?( @configuration_file )
        FileLock.new( @configuration_file ).readlock {|f|
          tmp = YAML.load f
          @conf = key_to_sym( tmp )
        }
      else
        @conf = {}
      end
    end

    #値を取得する。
    #names:: 値を示すパス 例) [:foo, :var]
    #default:: 値が存在しない場合の初期値
    #return:: 値
    def get( names, default )
      v = names.inject(@conf) {|conf,i|
        if conf.kind_of?(Hash)
          conf[i]
        else
          break default
        end
      }
      v == nil ? default : v
    end

    #値を設定する。
    #※設定した値は元のファイルには反映されない。プログラムを終了すると失われる。
    #names:: 値を示すパス 例) [:foo, :var]
    #value:: 値
    def set( names, value=nil)
      key = names.pop
      names.inject(@conf) {|conf, i|
        if conf[i].kind_of?(Hash)
          conf[i]
        elsif conf[i] == nil
          conf[i] = {}
        else
          raise "illegal key."
        end
      }[key] = value
    end

    #値が存在するか評価する。
    #names:: 値を示すパス 例) [:foo, :var]
    #return:: 値があればtrue
    def key?( names )
      v = names.inject(@conf) {|conf,i|
        if conf.kind_of?(Hash)
          conf[i]
        else
          break nil
        end
      }
      v != nil
    end

    private
    def key_to_sym( map )
      map.inject({}) {|r,e|
         v = e[1].kind_of?(Hash) ? key_to_sym( e[1] ) : e[1]
         r.store(e[0].to_sym, v)
         r
      }
    end
  end
end
