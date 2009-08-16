
module JIJI

  module AgentUtil

    #ブロックを指定のセーフレベルで実行する。
    #level:: セーフレベル
    def safe(level=4)
      Thread.fork {
        $SAFE = level
        yield if block_given?
      }.value
    end
  end

end