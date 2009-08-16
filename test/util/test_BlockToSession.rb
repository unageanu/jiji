#!/usr/bin/ruby

$: << "../lib"

require "runit/testcase"
require "runit/cui/testrunner"
require 'jiji/util/block_to_session'
require 'logger'
require 'csv'

class BlockToSessionTest <  RUNIT::TestCase
  
  # 基本動作のテスト
  def test_basic
    
    buff = ""
    s = Session.new {|wait|
      do_as( "a", "b", buff ) {|a,b,log|
        log << "#{a}.#{b}.wait."
        wait.call( a, b, log )
      }
    }
    assert_equals buff, "start.a.b.wait."
    
    # リクエストを送る
    assert_equals "result", s.request {|a,b,log|
      log << "#{a}.#{b}.req."
      "result"
    }
    assert_equals buff, "start.a.b.wait.a.b.req."
    
    assert_equals "result2", s.request {|a,b,log|
      log << "#{a}.#{b}.req."
      "result2"
    }
    assert_equals buff, "start.a.b.wait.a.b.req.a.b.req."
    
    # リクエスト中にエラー#呼び出し元に伝搬される
    begin
      s.request {|a,b,log|
        raise NameError.new("test")
      }
      fail
    rescue NameError
    end
    begin
      s.request {|a,b,log|
        raise Exception.new
      }
      fail
    rescue Exception
    end
    
    assert_equals "result3", s.request {|a,b,log|
      log << "#{a}.#{b}.req."
      "result3"
    }
    assert_equals buff, "start.a.b.wait.a.b.req.a.b.req.a.b.req."
    assert_equals "result4", s.request {|a,b,log|
      log << "#{a}.#{b}.req."
      "result4"
    }
    assert_equals buff, "start.a.b.wait.a.b.req.a.b.req.a.b.req.a.b.req."
    
    s.close
    assert_equals buff, "start.a.b.wait.a.b.req.a.b.req.a.b.req.a.b.req.end."
    
  end

  def do_as( a,b,log ) 
    begin
      log << "start."
      yield a, b, log
    ensure
      log << "end."
    end
  end

  # 基本動作のテスト
  def test_error_session
    s = create_session
    begin
      s.request {|x| x.call }
      fail
    rescue
      s.close
      s = create_session
      begin
        s.request {|x| x.call }
        fail
      rescue
      end
    end
    
    begin
      s.request {|x| x.call }
      fail
    rescue 
    end
  
  end

  def create_session
      return Session.new { |wait|
          wait.call( ErrorSession.new( "test" ) )
      }
  end


  #接続エラー時に使用するセッション
  #常にエラーをスローする。
  class ErrorSession
    def initialize(error)
      @error = error
    end
    def method_missing(name, *args, &block)
      raise @error
    end
  end

end