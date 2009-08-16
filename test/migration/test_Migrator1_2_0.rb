#!/usr/bin/ruby

$: << "../lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'fileutils'
require 'logger'
require 'jiji/configuration'
require 'jiji/migration/migrator1_2_0'
require 'kconv'

# Migrator1_2_0 のテスト
class Migrator1_2_0Test <  RUNIT::TestCase

  def setup
    @dir = File.dirname(__FILE__) + "/migrator1_2_0_test"
    FileUtils.rm_rf @dir

    @registry = {}
  end

  def teardown
    FileUtils.rm_rf @dir
  end

  # 実際のデータを変更するテスト
  def test_real_data
    FileUtils.cp_r File.dirname(__FILE__) + "/migrator1_2_0test_data", @dir

    # データ移行
    m = JIJI::Migration::Migrator1_2_0.new
    m.migrate( Struct.new( :process_dir, :server_logger ).new(
      @dir, Logger.new(STDOUT) ) )

    # 結果の確認
    dir = "#{@dir}/basic/out"
    out = JIJI::Output.new( "b4d92531-e381-4b40-85e4-1afd4e45030f", dir );
    assert_equals out.agent_name, "名称未設定エージェント1"
    assert_equals out.map{|o| o[1].options[:name]}, ["移動平均線"]

    out = JIJI::Output.new( "305a9448-78c6-4497-9659-c15f0a77bb3c", dir );
    assert_equals out.agent_name, "名称未設定エージェント2"
    assert_equals out.map{|o| o[1].options[:name]}, ["移動平均線"]

    out = JIJI::Output.new( "3ce90681-d7e6-45e5-b044-20f866dcd70c", dir );
    assert_equals out.agent_name, "不明"
    assert_equals out.map{|o| o[1].options[:name]}, ["移動平均線"]

    out = JIJI::Output.new( "05ac7126-0ae1-4394-a26e-b5cf80404fa6", dir );
    assert_equals out.agent_name, "不明"
    assert_equals out.map{|o| o[1].options[:name]}, ["移動平均線"]
    
    
    dir = "#{@dir}/illegal_props/out"
    out = JIJI::Output.new( "b4d92531-e381-4b40-85e4-1afd4e45030f", dir );
    assert_equals out.agent_name, "不明"
    assert_equals out.map{|o| o[1].options[:name]}, ["移動平均線"]

    out = JIJI::Output.new( "305a9448-78c6-4497-9659-c15f0a77bb3c", dir );
    assert_equals out.agent_name, "不明"
    assert_equals out.map{|o| o[1].options[:name]}, ["移動平均線"]

    out = JIJI::Output.new( "3ce90681-d7e6-45e5-b044-20f866dcd70c", dir );
    assert_equals out.agent_name, "不明"
    assert_equals out.map{|o| o[1].options[:name]}, ["移動平均線"]

    out = JIJI::Output.new( "05ac7126-0ae1-4394-a26e-b5cf80404fa6", dir );
    assert_equals out.agent_name, "不明"
    assert_equals out.map{|o| o[1].options[:name]}, ["移動平均線"]
    
    
    dir = "#{@dir}/no_props/out"
    out = JIJI::Output.new( "b4d92531-e381-4b40-85e4-1afd4e45030f", dir );
    assert_equals out.agent_name, "不明"
    assert_equals out.map{|o| o[1].options[:name]}, ["移動平均線"]

    out = JIJI::Output.new( "305a9448-78c6-4497-9659-c15f0a77bb3c", dir );
    assert_equals out.agent_name, "不明"
    assert_equals out.map{|o| o[1].options[:name]}, ["移動平均線"]

    out = JIJI::Output.new( "3ce90681-d7e6-45e5-b044-20f866dcd70c", dir );
    assert_equals out.agent_name, "不明"
    assert_equals out.map{|o| o[1].options[:name]}, ["移動平均線"]

    out = JIJI::Output.new( "05ac7126-0ae1-4394-a26e-b5cf80404fa6", dir );
    assert_equals out.agent_name, "不明"
    assert_equals out.map{|o| o[1].options[:name]}, ["移動平均線"]

  end

end

