#!/usr/bin/ruby

$: << "../../lib"
$: << "../../ext_lib"
$: << "../"

require "runit/testcase"
require "runit/cui/testrunner"
require "testutils"

# RateService のテスト
class RateServiceTest < Test::AbstractServiceTest
  
  def setup
    super
    @rs = Test::JsonRpcRequestor.new("rate")     
  end

  def teardown
    super
  end
  
  # レート一覧取得
  def test_basic
    
    ["1m", "10m", "6h","1d", "5d"].each {|s|
      
      puts "---" + s
      
      start = Time.now
      list = @rs.list( :EURJPY, s, Time.local(2008,8, 23).to_i, 120)
      puts "time:" + ( Time.now.to_f - start.to_f ).to_s
      
      puts list.length
      p list[0]
      
      #assert_equals list.length, 10
      list.each {|item|
        assert_equals item.length, 6
        #p item
      }
      
#      list = @rs.list_next( :EURJPY, s, Time.local(2008,8,24).to_i )
#      
#      puts list.length
#      p list[0]      
#      assert_equals list.length > 0, true
#      list.each {|item|
#        assert_equals item.length, 6
#        #p item
#      }
    }
    
  end
end

