
require 'thread'

# ブロックを渡して処理を行なうAPIを
# セッション風に使えるようにする
class Session
  def initialize
    @alive = true
    @alive_mutex = Mutex.new
    @q = Queue.new
    @t = Thread.fork {
      yield proc {|*args|
        while( @alive_mutex.synchronize { @alive } )
          req = @q.pop
          req.call( *args ) if req
        end
      }
    }
  end
  # リクエストを送る
  def request( &block )
    return unless block_given?
    req = Request.new(block)
    @q.push req
    req.wait
  end
  # セッションを破棄する
  def close
    @alive_mutex.synchronize { 
      @alive = false
    }
    @q.push nil
    @t.join
  end
  
  # リクエスト
  class Request
    def initialize( block )
      @mutex = Mutex.new
      @cv = ConditionVariable.new
      @finished = false
      @value = nil
      @error = nil
      @proc = proc {|*args|
        begin
          @value = block.call(*args)
        rescue Exception
          @error = $! 
        ensure
          @mutex.synchronize{
            @finished = true
            @cv.signal
          }
        end
      }
    end
    # リクエストの完了を待ち、結果を返す。
    def wait
      @mutex.synchronize{
        @cv.wait( @mutex ) until @finished
      }
      raise @error if @error
      @value
    end
    # リクエストを実行する。
    def call(*args)
      @proc.call(*args)
    end
  end
end