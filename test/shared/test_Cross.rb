#!/usr/bin/ruby

$: << "../lib"
$: << "../base/shared_lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'system/cross'

class CrossTest <  RUNIT::TestCase

  def test_cross
    cross = Cross.new
    assert_equals( cross.trend, 0 )
    assert_equals( cross.cross, :none )
    assert_equals( cross.up?, false )
    assert_equals( cross.down?, false )
    assert_equals( cross.cross_up?, false )
    assert_equals( cross.cross_down?, false )
    
    result = cross.next_data( 100, 110 )
    assert_equals( result, {:cross=>:none, :trend=>-1} )
    assert_equals( cross.trend, -1 )
    assert_equals( cross.cross, :none )
    assert_equals( cross.up?, false )
    assert_equals( cross.down?, true )
    assert_equals( cross.cross_up?, false )
    assert_equals( cross.cross_down?, false )
    
    result = cross.next_data( 95, 105 )
    assert_equals( result, {:cross=>:none, :trend=>-1} )
    assert_equals( cross.trend, -1 )
    assert_equals( cross.cross, :none )
    assert_equals( cross.up?, false )
    assert_equals( cross.down?, true )
    assert_equals( cross.cross_up?, false )
    assert_equals( cross.cross_down?, false )
    
    # 反転したらフラグが1度だけ立つ
    result = cross.next_data( 105, 100 )
    assert_equals( result, {:cross=>:up, :trend=>1} )
    assert_equals( cross.trend, 1 )
    assert_equals( cross.cross, :up )
    assert_equals( cross.up?, true )
    assert_equals( cross.down?, false )
    assert_equals( cross.cross_up?, true )
    assert_equals( cross.cross_down?, false )
    
    result = cross.next_data( 110, 105 )
    assert_equals( result, {:cross=>:none, :trend=>1} )
    assert_equals( cross.trend, 1 )
    assert_equals( cross.cross, :none )
    assert_equals( cross.up?, true )
    assert_equals( cross.down?, false )
    assert_equals( cross.cross_up?, false )
    assert_equals( cross.cross_down?, false )
    
    result = cross.next_data( 115, 110 )
    assert_equals( result, {:cross=>:none, :trend=>1} )
    assert_equals( cross.trend, 1 )
    assert_equals( cross.cross, :none )
    assert_equals( cross.up?, true )
    assert_equals( cross.down?, false )
    assert_equals( cross.cross_up?, false )
    assert_equals( cross.cross_down?, false )
    
    # 同じになっただけでは、クロスアップ/ダウンフラグは立たない
    result = cross.next_data( 115, 115 )
    assert_equals( result, {:cross=>:none, :trend=>0} )
    assert_equals( cross.trend, 0 )
    assert_equals( cross.cross, :none )
    assert_equals( cross.up?, false )
    assert_equals( cross.down?, false )
    assert_equals( cross.cross_up?, false )
    assert_equals( cross.cross_down?, false )
    
    result = cross.next_data( 115, 115 )
    assert_equals( result, {:cross=>:none, :trend=>0} )
    assert_equals( cross.trend, 0 )
    assert_equals( cross.cross, :none )
    assert_equals( cross.up?, false )
    assert_equals( cross.down?, false )
    assert_equals( cross.cross_up?, false )
    assert_equals( cross.cross_down?, false )
    
    # 反転したタイミンクでフラグが立つ
    result = cross.next_data( 115, 120 )
    assert_equals( result, {:cross=>:down, :trend=>-1} )
    assert_equals( cross.trend, -1 )
    assert_equals( cross.cross, :down )
    assert_equals( cross.up?, false )
    assert_equals( cross.down?, true )
    assert_equals( cross.cross_up?, false )
    assert_equals( cross.cross_down?, true )
    
    result = cross.next_data( 120, 125 )
    assert_equals( result, {:cross=>:none, :trend=>-1} )
    assert_equals( cross.trend, -1 )
    assert_equals( cross.cross, :none )
    assert_equals( cross.up?, false )
    assert_equals( cross.down?, true )
    assert_equals( cross.cross_up?, false )
    assert_equals( cross.cross_down?, false )
    
    # 同じになって元に戻った場合
    # クロスアップフラグは立たない。
    result = cross.next_data( 120, 120 )
    assert_equals( result, {:cross=>:none, :trend=>0} )
    assert_equals( cross.trend, 0 )
    assert_equals( cross.cross, :none )
    assert_equals( cross.up?, false )
    assert_equals( cross.down?, false )
    assert_equals( cross.cross_up?, false )
    assert_equals( cross.cross_down?, false )
    
    result = cross.next_data( 115, 115 )
    assert_equals( result, {:cross=>:none, :trend=>0} )
    assert_equals( cross.trend, 0 )
    assert_equals( cross.cross, :none )
    assert_equals( cross.up?, false )
    assert_equals( cross.down?, false )
    assert_equals( cross.cross_up?, false )
    assert_equals( cross.cross_down?, false )
    
    result = cross.next_data( 120, 125 )
    assert_equals( result, {:cross=>:down, :trend=>-1} )
    assert_equals( cross.trend, -1 )
    assert_equals( cross.cross, :down )
    assert_equals( cross.up?, false )
    assert_equals( cross.down?, true )
    assert_equals( cross.cross_up?, false )
    assert_equals( cross.cross_down?, true )
    
    result = cross.next_data( 120, 125 )
    assert_equals( result, {:cross=>:none, :trend=>-1} )
    assert_equals( cross.trend, -1 )
    assert_equals( cross.cross, :none )
    assert_equals( cross.up?, false )
    assert_equals( cross.down?, true )
    assert_equals( cross.cross_up?, false )
    assert_equals( cross.cross_down?, false )
  end
end