#!/usr/bin/ruby

$: << "../lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'fileutils'
require 'jiji/configuration'
require 'jiji/migration/migrator1_1_0'

# Migrator1_1_0 のテスト
class Migrator1_1_0Test <  RUNIT::TestCase

  def setup
    @dir = File.dirname(__FILE__) + "/migrator1_1_0_test"
    FileUtils.rm_rf @dir
    FileUtils.mkdir_p "#{@dir}/conf"
    
    @registry = {}
  end

  def teardown
    FileUtils.rm_rf @dir
  end
  
  # 実際のデータを変更するテスト
  def test_real_data
    FileUtils.cp_r File.dirname(__FILE__) + "/migrator1_1_0test_data/configuration.yaml", "#{@dir}/conf"
    
    assert_equals( YAML.load_file("#{@dir}/conf/configuration.yaml"), {
      "server"=>{ "port"=>8080 },
      "securities"=>{ "account"=>{
        "user"=>"foo",
        "password"=>"xxxx"
      }},
      "foo"=>{"var"=>"aaa"}
    })
    
    # データ移行
    m = JIJI::Migration::Migrator1_1_0.new
    m.migrate( Struct.new( :base_dir, :conf ).new( @dir, JIJI::Configuration.new ) )
    
    assert_equals( YAML.load_file("#{@dir}/conf/configuration.yaml"), {
      :server=>{ :port=>8080 },
      :securities=>{
        :type=>:click_securities_demo, 
        :user=>"foo",
        :password=>"xxxx"
      },
      :foo=>{:var=>"aaa"}
    })
  end
  
end

