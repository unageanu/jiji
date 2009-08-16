#!/usr/bin/ruby

$: << "../lib"
$: << File.dirname(__FILE__) + "/test"
$: << File.dirname(__FILE__) + "/error_test"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'logger'
require 'jiji/plugin/plugin_loader'

# Loader のテスト
class LoaderTest <  RUNIT::TestCase

  # 基本動作のテスト
  def test_basic
    # ロード前は空
    assert_equals [], JIJI::Plugin.get(:test)
    
    # ロード
    loader = JIJI::Plugin::Loader.new
    loader.server_logger = Logger.new STDOUT
    loader.load
    
    # ./test以下の"jiji_plugin.rb"がロードされる。
    assert_equals ["test"], JIJI::Plugin.get(:test)
    
    # テスト用のplugin gemがインストールされていれば aaa,bbb が表示される。
    puts JIJI::Plugin.get(:test_gem) 
  end
end

