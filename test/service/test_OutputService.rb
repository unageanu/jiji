#!/usr/bin/ruby

$: << "../../lib"
$: << "../../ext_lib"
$: << "../"

require "runit/testcase"
require "runit/cui/testrunner"
require "testutils"

# OutputService のテスト
class OutputServiceTest < Test::AbstractServiceTest
  
  def setup
    super
    @s = Test::JsonRpcRequestor.new("output")     
  end

  def teardown
    super
  end
  
  # レート一覧取得
  def test_basic
      
    puts "---"
    
    list = @s.list_outputs("rmt")
    puts list.join(",")
    
  end
end

