#!/usr/bin/ruby

$: << "../lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'rubygems'
require 'needle'
require 'jiji/util/synchronize_interceptor'
require 'fileutils'

class SynchronizeInterceptorTest <  RUNIT::TestCase
  
  def setup
    @dir = File.dirname(__FILE__) + "/CSVTest.tmp"
    FileUtils.mkdir_p @dir    
  end

  def teardown
    FileUtils.rm_rf @dir
  end

  def test_basic
    
    # レジストリ
    p = proc {
      5.times {|i| print "#{i},"; sleep 0.1 }
    }
    registry = Needle::Registry.define {|builder|
      builder.loop_no { p }
      builder.loop_x1 { p }
      builder.loop_x2 { p }
      builder.loop_y1 { p }
      builder.loop_y2 { p }
    }
    
    # インターセプタを適用
    registry.intercept( :loop_x1 ).with { SynchronizeInterceptor }.with_options( :id=>"x" )
    registry.intercept( :loop_x2 ).with { SynchronizeInterceptor }.with_options( :id=>"x" )
    registry.intercept( :loop_y1 ).with { SynchronizeInterceptor }.with_options( :id=>"y" )
    registry.intercept( :loop_y2 ).with { SynchronizeInterceptor }.with_options( :id=>"y" )
    
    loops = [
      :loop_no, :loop_x1, :loop_x2, :loop_y1, :loop_y2
    ]
    loops.each {|a|
      loops.each {|b|
        puts "\n\n---#{a} x #{b}"
        [registry[a],registry[b]].map {|x|
          Thread.fork(x) {|l| l.call }
        }.each{|t| t.value }
      }
    }
  end
  
  # 同じインターセプタが2重に適用されている場合のテスト
  def test_dual
    registry = Needle::Registry.new {|r|
        r.register( :a ) {
          proc { puts "aaa" }
        }
        r.register( :b ) {
          a = r.a
          proc { a.call; puts "bbb" }
        }
    }
    registry.intercept( :a ).with { SynchronizeInterceptor }.with_options( :id=>"x" )
    registry.intercept( :b ).with { SynchronizeInterceptor }.with_options( :id=>"x" )
    
    b = registry.b
    3.times{|i| b.call }
  end
 
  
end