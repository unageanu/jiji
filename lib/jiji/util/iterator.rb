
# イテレータ
class Iterator
  # 列挙します
  def each
    begin
      while next?
        yield self.next
      end
    ensure
      self.close
    end
  end
  # 次があるか評価する
  def next?
  end
  # 次の要素を取得
  def next
  end
  # イテレータを破棄
  def close
  end
end

# 空のイテレータ
class EmptyIterator < Iterator
  def next?; false; end
  def next; nil; end
end

# フィルタ
class Filter < Iterator
  def initialize( it, &block )
    super()
    @it = it
    @test = block
    inner_next
  end
  def next?
    @has_next
  end
  def next
    raise "illegal state." unless next?
    begin
      return @next_element
    ensure
      inner_next
    end
  end
  def close
    @it.close if @it
  end

  private
  def inner_next
    while @it.next?
      item = @it.next
      matches = @test.call( item )
      if matches == :break
        break
      elsif matches == :true || matches == true
        @has_next = true
        @next_element = item
        return
      end
    end
    @has_next = false
    @next_element = nil
  end
end