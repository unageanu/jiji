
require 'jiji/error'
require 'jiji/util/file_lock'
require 'set'

module JIJI

  module Permitted
    def permitted_request( *args, &block )
      r = JIJI::Permitter::Request.new( self, _function_name, args, 
        block, @permitter_allows, @permitter_proxy_result )
      @permitter << r
      return r.wait
    end
    def _function_name
      if /^(.+?):(\d+)(?::in `(.*)')?/ =~ caller.first
        return $3
      end
    end
    attr :permitter, true
    attr :permitter_allows, true
    attr :permitter_proxy_result, true
  end

  #==任意のオブジェクトのAPIをセーフレベルの高い環境から呼び出せるようにする。
  class Permitter
    # コンストラクタ
    #*pool_size*:: スレッドプールのサイズ
    def initialize( pool_size=5, level=2 )
      @alive = true
      @alive_mutex = Mutex.new
      @q = Queue.new
      @ts = []
      pool_size.times {
	      @ts << Thread.fork {
	        $SAFE = level
          while( @alive_mutex.synchronize { @alive } )
            req = @q.pop
            req.exec(self) if req
          end
	      }
      }
    end
    # リクエストを追加する。
    def <<(request)
      @q.push request
    end
    # インスタンスを破棄する。不要になった場合に必ず呼び出すこと。
    def close
      @alive_mutex.synchronize {
        @alive = false
      }
      @ts.length.times {
        @q.push nil
      }
      @ts.each {|t| t.join }
    end
    # 指定したインスタンスのAPIをセーフレベルの高い環境から呼び出せるようにする。
    #*object*:: APIの呼び出しを許可するオブジェクト
    #*allows*:: 許可するAPIを示す正規表現の配列
    #*proxy_result*:: 戻り値もプロキシを設定するAPIを示す正規表現の配列
    def proxy( object, allows=[], proxy_result=[])
      clazz = class << object
        include JIJI::Permitted
        self
      end
      object.permitter = self
      object.permitter_allows = allows
      object.permitter_proxy_result = proxy_result
      object.methods.each {|name|
        next unless allows.find {|a| name.to_s =~ a }

        # もともとのメソッドは、別名でキープしておく
        old = name.to_s + "_without_permittion"
        # 2重のアスペクト適用を防ぐ。
        next if clazz.method_defined? old.to_sym
        
        clazz.__send__(:alias_method, old.to_sym, name.to_sym )
        # インターセプタ適用対象のメソッドを上書きで定義。
        clazz.__send__(:alias_method, name.to_sym, :permitted_request )
      }
      object
    end

    # メソッド呼び出しリクエスト
    class Request
      def initialize( receiver, name, args, block=nil, allows=[], proxy_result=[] )
        @name = name
        @args = args
        @block = block
        @receiver = receiver
        @mutex = Mutex.new
        @cv = ConditionVariable.new
        @finished = false
        @value = nil
        @error = nil
        @allows = allows
        @proxy_result = proxy_result
      end
      # リクエストの完了を待ち、結果を返す。
      def wait
        @mutex.synchronize{
          @cv.wait( @mutex ) until @finished
        }
        raise @error if @error
        @value
      end
      # リクエストを実行する
      def exec( permitter )
        begin
          m = @name + "_without_permittion"
          @value = @block ? @receiver.send( m, *@args, &@block ) : @receiver.send( m, *@args )
          if @proxy_result.find {|a| @name.to_s =~ a }
            @value = permitter.proxy( @value, @allows, @proxy_result )
          end
        rescue Exception
          @error = $!
        ensure
          @mutex.synchronize{
            @finished = true
            @cv.signal
          }
        end
      end
    end
  end

end