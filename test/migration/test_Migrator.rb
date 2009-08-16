#!/usr/bin/ruby

$: << "../lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/migration/migrator'

# Migrator のテスト
class MigratorTest <  RUNIT::TestCase

  def setup
    @dir = File.dirname(__FILE__) + "/migrator_test"
    FileUtils.mkdir_p @dir
    
    @registry = {}
  end

  def teardown
    FileUtils.rm_rf @dir
  end

  # 基本動作のテスト
  def test_basic
    
    log = []
    
    # バージョンファイルはないので、1.0.0と判定される。
    # 同じバージョンのものは実行されない
    # 下位バージョンのものは実行されない。
    m = JIJI::Migration::Migrator.new
    m.registry = @registry
    m.version_file = "#{@dir}/version"
    m.server_logger = Logger.new(STDOUT)
    m.migrators = [
      {:version=>Gem::Version.new("1.1.0"), :migrator=>TestMigrator.new( "1.1.0", log )},
      {:version=>Gem::Version.new("1.0.0"), :migrator=>TestMigrator.new( "1.0.0", log )}, # 実行されない
      {:version=>Gem::Version.new("2.0.1"), :migrator=>TestMigrator.new( "2.0.1", log )},
      {:version=>Gem::Version.new("1.0.2"), :migrator=>TestMigrator.new( "1.0.2", log )}, 
      {:version=>Gem::Version.new("0.9.99"), :migrator=>TestMigrator.new( "0.9.99", log )} # 実行されない
    ]
    assert_equals( m.version.to_s, "1.0.0" )
    
    # データ移行を実行
    m.migrate
    assert_equals( log, ["1.0.2","1.1.0","2.0.1"] )
    assert_equals( m.version.to_s, "2.0.1" )

    # 再実行→すでに最新バージョンなので何も実行されない
    log.clear
    m.migrate
    assert_equals( log, [] )
    assert_equals( m.version.to_s, "2.0.1" )
    
    # 新しいデータ移行処理を追加。
    # 現在のバージョンより上位のもののみ実行される。
    m = JIJI::Migration::Migrator.new
    m.registry = @registry
    m.version_file = "#{@dir}/version"
    m.server_logger = Logger.new(STDOUT)
    m.migrators = [
      {:version=>Gem::Version.new("1.0.0"), :migrator=>TestMigrator.new( "1.0.0", log )}, # 実行されない
      {:version=>Gem::Version.new("2.0.1"), :migrator=>TestMigrator.new( "2.0.1", log )}, # 実行されない
      {:version=>Gem::Version.new("2.1.5"), :migrator=>TestMigrator.new( "2.1.5", log )}, # 実行される
    ]
    assert_equals( m.version.to_s, "2.0.1" )
    m.migrate
    assert_equals( log, ["2.1.5"] )
    assert_equals( m.version.to_s, "2.1.5" )
  end
  
  # データ移行の途中でエラーになる場合のテスト
  def test_error
    log = []
    
    # バージョンファイルはないので、1.0.0と判定される。
    # エラーになったバージョンまで移行できる。
    m = JIJI::Migration::Migrator.new
    m.registry = @registry
    m.version_file = "#{@dir}/version"
    m.server_logger = Logger.new(STDOUT)
    m.migrators = [
      {:version=>Gem::Version.new("1.1.0"), :migrator=>TestMigrator.new( "1.1.0", log )}, # 実行される
      {:version=>Gem::Version.new("1.0.0"), :migrator=>TestMigrator.new( "1.0.0", log )}, # 実行されない
      {:version=>Gem::Version.new("2.0.1"), :migrator=>TestMigrator.new( "2.0.1", log )}, # エラーのため実行されない
      {:version=>Gem::Version.new("1.1.2"), :migrator=>ErrorMigrator.new}, # エラー
      {:version=>Gem::Version.new("0.9.99"), :migrator=>TestMigrator.new( "0.9.99", log )} # 実行されない
    ]
    assert_equals( m.version.to_s, "1.0.0" )
    m.migrate
    assert_equals( log, ["1.1.0"] )
    assert_equals( m.version.to_s, "1.1.0" )
    
    log.clear
    m.migrate
    assert_equals( log, [] )
    assert_equals( m.version.to_s, "1.1.0" )
  end
  
  class TestMigrator
    def initialize(id,log)
      super()
      @id = id
      @log = log
    end
    def migrate( registry )
      @log << @id
    end
  end
  class ErrorMigrator
    def migrate( registry )
      raise "test"
    end
  end
end

