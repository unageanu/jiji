#!/usr/bin/ruby

$: << "../lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'fileutils'
require 'jiji/migration/migrator1_0_3'

# Migrator1_0_3 のテスト
class Migrator1_0_3Test <  RUNIT::TestCase

  def setup
    @dir = File.dirname(__FILE__) + "/migrator1_0_3_test"
    FileUtils.rm_rf @dir
    FileUtils.mkdir_p @dir
    
    @registry = {}
  end

  def teardown
    FileUtils.rm_rf @dir
  end

  # 基本動作のテスト
  def test_basic
    
    FileUtils.mkdir_p "#{@dir}/rmt/out/a/b"
    FileUtils.mkdir_p "#{@dir}/rmt/out/a/c"
    FileUtils.mkdir_p "#{@dir}/rmt/out/x/"
    FileUtils.mkdir_p "#{@dir}/rmt/outa/a/"
    FileUtils.mkdir_p "#{@dir}/foo/out/a/b"
    FileUtils.mkdir_p "#{@dir}/foo/var"
    
    # 更新されるファイル
    files = [
      "#{@dir}/rmt/out/a/b/meta.yaml",
      "#{@dir}/rmt/out/a/c/meta.yaml",
      "#{@dir}/rmt/out/x/meta.yaml",
      "#{@dir}/rmt/out/a/meta.yaml",
      "#{@dir}/rmt/out/meta.yaml",
      "#{@dir}/foo/out/a/b/meta.yaml",
      "#{@dir}/foo/out/a/meta.yaml"
    ]
    # 更新されないファイル
    ignore_files = [
      "#{@dir}/rmt/out/a/b/foo.yaml",
      "#{@dir}/rmt/outa/a/meta.yaml",
      "#{@dir}/rmt/meta.yaml",
      "#{@dir}/meta.yaml",
      "#{@dir}/foo/var/meta.yaml"
    ]
    props = {
      "name"=>"名前",
      :column_count=>2,
      "type"=>"graph",
      :graph_type=> :rate,
      "colors"=> ["#ff33bb","#557777"],
      "visible"=> true,
      :colors => ["#ff33bb","#557777"]
    }
    (files + ignore_files).each {|file|
      open( file, "w" ) { |f| f.write( YAML.dump( props )) }
      assert_equals( YAML.load_file(file), props)
    }
    
    # データ移行
    m = JIJI::Migration::Migrator1_0_3.new
    m.migrate( Struct.new( :process_dir ).new( @dir ) )
    
    converted_props = {
      :name=>"名前",
      :column_count=>2,
      :type=>"graph",
      :graph_type=> :rate,
      :visible=> true,
      :colors => ["#ff33bb","#557777"]
    }
    files.each {|file|assert_equals( YAML.load_file(file), converted_props)}
    ignore_files.each {|file|assert_equals( YAML.load_file(file), props)}
  end
  
  # 実際のデータを変更するテスト
  def test_real_data
    FileUtils.cp_r File.dirname(__FILE__) + "/migrator1_0_3test_data/rmt", @dir
    
    # データ移行
    m = JIJI::Migration::Migrator1_0_3.new
    m.migrate( Struct.new( :process_dir ).new( @dir ) )
    
    assert_equals( YAML.load_file("#{@dir}/rmt/out/M2NlOTA2ODEtZDdlNi00NWU1LWIwNDQtMjBmODY2ZGNkNzBj/56e75YuV5bmz5Z2H57ea/meta.yaml"), {
      :name=>"移動平均線",
      :column_count=> 2,
      :graph_type=> :rate,
      :type=> "graph",
      :colors=>["#779999","#557777"]
    })
    assert_equals( YAML.load_file("#{@dir}/rmt/out/NjM5YWFhZmQtNDFjNy00NjUxLWIwYmItNTc3ZjAyZTg5ODA5/56e75Yuasdwqdd/meta.yaml"), {
      :name=>"移動平均線",
      :column_count=> 2,
      :graph_type=> :rate,
      :visible=>true,
      :type=> "graph",
      :colors=>["#ff33bb","#557777"]
    })
    assert_equals( YAML.load_file("#{@dir}/rmt/out/NjM5YWFhZmQtNDFjNy00NjUxLWIwYmItNTc3ZjAyZTg5ODA5/56e75YuV5bmz5Z2H57ea/meta.yaml"), {
      :name=>"移動平均線",
      :column_count=> 2,
      :graph_type=> :rate,
      :visible=>true,
      :type=> "graph",
      :colors=>["#ff33bb","#557777"]
    })
  end
  
end

