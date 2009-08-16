
require 'thread'
require 'set'

# 同時実行抑制インターセプタ
class SynchronizeInterceptor

  @@pool = {}
  @@pool_mutex = Mutex.new

  # コンストラクタ
  def initialize( point, options )
    @id = options[:id] || :default
    @mutex = mutex( @id )
  end

  def process( chain, context )
    # 2重ロックの回避
    set = Thread.current[:synchronize_interceptor_locked] ||= Set.new
    if set.include? @id
      chain.process_next( context )
    else
      set.add( @id )
      begin
        @mutex.synchronize {
          chain.process_next( context )
        }
      ensure
        set.delete( @id )
      end
    end
  end

  # IDに対応するmutexを取得する
  def mutex( id )
    @@pool_mutex.synchronize {
       @@pool[id] ||= Mutex.new
    }
  end

end
