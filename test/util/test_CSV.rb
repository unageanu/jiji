#!/usr/bin/ruby

$: << "../lib"

require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/util/csv_append_support'
require 'fileutils'

class CSVTest <  RUNIT::TestCase
  
  def setup
    @dir = File.dirname(__FILE__) + "/CSVTest.tmp"
    FileUtils.mkdir_p @dir    
  end

  def teardown
    FileUtils.rm_rf @dir
  end

  def test_append
    
    CSV.open( "#{@dir}/test.csv", "w" ){ |csv|
      csv << ["a", 1,  "c"]
      csv << ["b", 10,  "x"]
    }
    
    list = CSV.read( "#{@dir}/test.csv")
    assert_equals list, [["a", "1",  "c"], ["b", "10",  "x"]]
    
    # 追記
    CSV.open( "#{@dir}/test.csv", "a"){ |csv|
      csv << ["c", 2,  "あ"]
    }
    list = CSV.read( "#{@dir}/test.csv")
    assert_equals list, [["a", "1",  "c"], ["b", "10",  "x"],["c", "2",  "あ"]]
    
    # さらに追記
    CSV.open( "#{@dir}/test.csv", "a"){ |csv|
      csv << ["d", "x",  "い"]
      csv << ["d", "x",  "い"]
    }
    list = CSV.read( "#{@dir}/test.csv")
    assert_equals list, [["a", "1",  "c"], ["b", "10",  "x"],["c", "2",  "あ"],["d", "x",  "い"],["d", "x",  "い"]]
  
    # 更新
    CSV.open( "#{@dir}/test.csv", "w" ){ |csv|
    }
    
    list = CSV.read( "#{@dir}/test.csv")
    assert_equals list, []
    
    
    # 空の状態から追記
    CSV.open( "#{@dir}/test.csv", "a"){ |csv|
      csv << ["d", "x",  "い"]
      csv << ["d", "x",  "い"]
    }
    list = CSV.read( "#{@dir}/test.csv")
    assert_equals list, [["d", "x",  "い"],["d", "x",  "い"]]
  
    CSV.open( "#{@dir}/test2.csv", "a" ){ |csv|
      csv << ["d", "x",  "い"]
      csv << ["d", "x",  "い"]
    }
    list = CSV.read( "#{@dir}/test.csv")
    assert_equals list, [["d", "x",  "い"],["d", "x",  "い"]]
    
  end
  
  def test_escape
    
    # 「改行」や「,」「半角スペース」を書いてみる
    CSV.open( "#{@dir}/test.csv", "w" ){ |csv|
      csv << ["\n\t, ", 1,  "\n\t, "]
      csv << ["\n\t, ", 10,  "\n\t, "]
    }
    
    list = CSV.read( "#{@dir}/test.csv")
    assert_equals list, [["\n\t, ", "1",  "\n\t, "], ["\n\t, ", "10",  "\n\t, "]]
    
  end
  
end