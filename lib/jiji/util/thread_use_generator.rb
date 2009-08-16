require 'thread'

# スレッドを使ったGenerator
class ThreadUseGenerator
  def initialize( enum, buff_size=nil )
    @alive = true
    @alive_mutex = Mutex.new
    @q = buff_size ? SizedQueue.new( buff_size ) : Queue.new

    @end = Object.new
    @t = Thread.fork {
      begin
        enum.each {|*items|
          break unless @alive_mutex.synchronize { @alive }
          @q << items
        }
      ensure
        @q << @end
      end
    }
    Thread.pass

    @has_next = true
    inner_next
  end

  def next?
    @has_next
  end
  def next
    raise "illegal state." unless next?
    begin
      @next_element
    ensure
      inner_next
    end
  end
  def close
    @alive_mutex.synchronize {
      @alive = false
    }
    @has_next = false
    @q.clear
    @t.join
  end
private
  def inner_next
    item = @q.pop
    @has_next = false if @end.equal? item
    @next_element = item
  end
end
