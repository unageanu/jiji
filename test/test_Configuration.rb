#!/usr/bin/ruby

$: << "../lib"


require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/configuration'

class ConfigurationTest <  RUNIT::TestCase

  def setup
  end

  def teardown
  end

  def test_basic
    conf = JIJI::Configuration.new  File.dirname(__FILE__) + "/test_Configuration_a.yaml"
    
    assert_equals conf.key?( [:a] ), true
    assert_equals conf.key?( [:aa, :a] ), true
    assert_equals conf.key?( [:x] ), false
    
    assert_equals "aaa", conf.get( [:a], "foo" )
    assert_equals 10,    conf.get( [:b], "foo" )
    assert_equals "foo", conf.get( [:c], "foo" )
    assert_equals "foo", conf.get( [:d], "foo" )
    assert_equals "aaa", conf.get( [:aa, :a], "foo" )
    assert_equals "foo", conf.get( [:aa, :b], "foo" )
    assert_equals "foo", conf.get( [:aa, :a, :b], "foo" )
    assert_equals "foo", conf.get( [:bb], "foo" )
    assert_equals "foo", conf.get( [:bb, :b], "foo" )
        
    conf.set( [:a], "x" )
    conf.set( [:x], "x" )
    conf.set( [:aa, :a], "x" )
    conf.set( [:aa, :x], "x" )
    conf.set( [:xxx, :xx, :x], "x" )
    
    assert_equals "x", conf.get( [:a], "foo" )
    assert_equals "x", conf.get( [:x], "foo" )
    assert_equals "x", conf.get( [:aa, :a], "foo" )
    assert_equals "x", conf.get( [:aa, :x], "foo" )
    assert_equals "x", conf.get( [:xxx, :xx, :x], "foo" )
    
    
    conf = JIJI::Configuration.new  File.dirname(__FILE__) + "/not found.yaml"
    assert_equals "foo", conf.get( [:a], "foo" )
    assert_equals "foo", conf.get( [:b], "foo" )
    assert_equals "foo", conf.get( [:c], "foo" )
    assert_equals "foo", conf.get( [:d], "foo" )
    assert_equals "foo", conf.get( [:aa, :a], "foo" )
    assert_equals "foo", conf.get( [:aa, :b], "foo" )
    assert_equals "foo", conf.get( [:aa, :a, :b], "foo" )
    assert_equals "foo", conf.get( [:bb], "foo" )
    assert_equals "foo", conf.get( [:bb, :b], "foo" )
    
  end

end