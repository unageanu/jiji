#!/usr/bin/ruby

$: << "../lib"

require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/dao/file_system_dao'
require 'rubygems'
require 'test_utils'

#FileSystemDaoのテスト
class FileSystemDaoTest <  RUNIT::TestCase

  include Test::Constants

  #前準備
  def setup
    @dir = File.dirname(__FILE__) + "/FileSystemDao.tmp"
    FileUtils.mkdir_p @dir

    @dao = JIJI::Dao::FileSystemDao.new( @dir )

    @dao.mkcol "folder1"
    @dao.add( "file1", "1" )
    @dao.put( "file2", "2" )
    @dao.add( "folder1/file1-1", "1-1" )
    @dao.put( "folder1/file1-2", "1-2" )
  end

  #後始末
  def teardown
    FileUtils.rm_rf @dir
  end

  #基本動作のテスト
  def test_basic

    #フォルダとファイルを追加で作成
    @dao.mkcol "folder2"
    @dao.mkcol "folder2/folder2-1"
    @dao.mkcol "folder2/folder2-2"
    @dao.mkcol "folder2/folder2-1/folder2-1-1"
    @dao.mkcol "folder2/folder2-1/folder2-1-2"
    @dao.mkcol "folder2/folder2-2/folder2-2-1"
    @dao.add( "folder2/folder2-1/folder2-1-1/file2-1-1", "2-1-1" )
    @dao.put( "folder2/folder2-1/folder2-1-1/file2-1-2", "2-1-2" )

    assert_equals( list, [
      "folder1:directory",
      "folder2:directory",
      "file1:file",
      "file2:file"
    ])
    assert_equals( list("folder1"), [
      "file1-1:file",
      "file1-2:file"
    ])
    assert_equals( list("folder2"), [
      "folder2-1:directory",
      "folder2-2:directory"
    ])
    assert_equals( list("folder2/folder2-1"), [
      "folder2-1-1:directory",
      "folder2-1-2:directory"
    ])
    assert_equals( list("folder2/folder2-2"), [
      "folder2-2-1:directory"
    ])
    assert_equals( list("folder2/folder2-1/folder2-1-1"), [
      "file2-1-1:file",
      "file2-1-2:file"
    ])
    assert_equals( list("folder2/folder2-1/folder2-1-2"), [])
    assert_equals( list("folder2/folder2-2/folder2-2-1"), [])


    #再帰探索
    assert_equals( list_r, [
      "folder1:directory",
      "folder2:directory",
      "folder2/folder2-1:directory",
      "folder2/folder2-1/folder2-1-1:directory",
      "folder2/folder2-1/folder2-1-2:directory",
      "folder2/folder2-2:directory",
      "folder2/folder2-2/folder2-2-1:directory",
      "file1:file",
      "file2:file",
      "folder1/file1-1:file",
      "folder1/file1-2:file",
      "folder2/folder2-1/folder2-1-1/file2-1-1:file",
      "folder2/folder2-1/folder2-1-1/file2-1-2:file"
    ]);
    assert_equals( list_r("folder1"), [
      "folder1/file1-1:file",
      "folder1/file1-2:file"
    ])
    assert_equals( list_r("folder2"), [
      "folder2/folder2-1:directory",
      "folder2/folder2-1/folder2-1-1:directory",
      "folder2/folder2-1/folder2-1-2:directory",
      "folder2/folder2-2:directory",
      "folder2/folder2-2/folder2-2-1:directory",
      "folder2/folder2-1/folder2-1-1/file2-1-1:file",
      "folder2/folder2-1/folder2-1-1/file2-1-2:file"
    ])
    assert_equals( list_r("folder2/folder2-1"), [
      "folder2/folder2-1/folder2-1-1:directory",
      "folder2/folder2-1/folder2-1-2:directory",
      "folder2/folder2-1/folder2-1-1/file2-1-1:file",
      "folder2/folder2-1/folder2-1-1/file2-1-2:file"
    ])
    assert_equals( list_r("folder2/folder2-2"), [
      "folder2/folder2-2/folder2-2-1:directory"
    ])
    assert_equals( list_r("folder2/folder2-1/folder2-1-1"), [
      "folder2/folder2-1/folder2-1-1/file2-1-1:file",
      "folder2/folder2-1/folder2-1-1/file2-1-2:file"
    ])
    assert_equals( list_r("folder2/folder2-1/folder2-1-2"), [])
    assert_equals( list_r("folder2/folder2-2/folder2-2-1"), [])

    #取得
    assert_equals( @dao.get("file1"), "1")
    assert_equals( @dao.get("file2"), "2")
    assert_equals( @dao.get("folder1/file1-1"), "1-1")
    assert_equals( @dao.get("folder1/file1-2"), "1-2")
    assert_equals( @dao.get("folder2/folder2-1/folder2-1-1/file2-1-1"), "2-1-1")
    assert_equals( @dao.get("folder2/folder2-1/folder2-1-1/file2-1-2"), "2-1-2")

    #更新
    @dao.put( "file1", "100" )
    assert_equals( @dao.get("file1"), "100")

    #移動
    @dao.rename("file1", "file3")
    @dao.move("file2", "folder1")
    @dao.rename("folder1/file2", "folder1/file4")
    @dao.rename("folder1", "folder3")
    @dao.move("folder2", "folder3")
    assert_equals( list, [
      "folder3:directory",
      "file3:file"
    ])
    assert_equals( list("folder3"), [
      "folder2:directory",
      "file1-1:file",
      "file1-2:file",
      "file4:file"
    ])

    #コピー
    @dao.copy("file3", "file1")
    @dao.copy("folder3/file4", "file2")
    @dao.copy("folder3", "folder1")
    @dao.copy("folder3/folder2", "folder2")
    assert_equals( list, [
      "folder1:directory",
      "folder2:directory",
      "folder3:directory",
      "file1:file",
      "file2:file",
      "file3:file"
    ])
    assert_equals( list("folder3"), [
      "folder2:directory",
      "file1-1:file",
      "file1-2:file",
      "file4:file"
    ])

    #削除
    @dao.delete("file3")
    @dao.delete("folder3")
    @dao.delete("folder1/file1-2")
    @dao.delete("folder1/folder2")
    assert_equals( list, [
      "folder1:directory",
      "folder2:directory",
      "file1:file",
      "file2:file"
    ])
    assert_equals( list("folder1"), [
      "file1-1:file",
      "file4:file"
    ])

  end

  ILLEGAL_PATHS = [
    "./folder1",
    "../folder1",
    "folder1/../..",
    "folder1/../../",
    "folder1/.",
    "folder1/.test",
    "/ /",
    "/日本語もエラー"
  ]

  #一覧取得の異常系のテスト
  def test_error_list

    #一覧に"."で始まるファイル/フォルダは含まれない。
    FileUtils.touch( "#{@dir}/.test" )
    FileUtils.mkdir( "#{@dir}/.test_folder" )
    assert_equals( list, [
      "folder1:directory",
      "file1:file",
      "file2:file"
    ])

    #パスが不正
    ILLEGAL_PATHS.each {|path|
      assert_raise( JIJI::UserError, JIJI::ERROR_ILLEGAL_NAME ) {
        @dao.list( path )
      }
    }

    #ディレクトリが存在しない
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.list( "not_found" )
    }
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.list( "folder1/not_found" )
    }


    #ファイル
    assert_raise( JIJI::UserError, JIJI::ERROR_IS_NOT_FOLDER ) {
      @dao.list( "file1" )
    }
    assert_raise( JIJI::UserError, JIJI::ERROR_IS_NOT_FOLDER ) {
      @dao.list( "folder1/file1-1" )
    }
  end

  #ファイル取得の異常系のテスト
  def test_error_get
    #パスが不正
    ILLEGAL_PATHS.each {|path|
      assert_raise( JIJI::UserError, JIJI::ERROR_ILLEGAL_NAME ) {
        @dao.get( path )
      }
    }

    #ファイルが存在しない
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.get( "not_found" )
    }
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.get( "folder1/not_found" )
    }

    #フォルダが指定された
    assert_raise( JIJI::UserError, JIJI::ERROR_IS_NOT_FILE ) {
      @dao.get( "folder1" )
    }
  end

  #ファイル更新の異常系のテスト
  def test_error_put
    #パスが不正
    ILLEGAL_PATHS.each {|path|
      assert_raise( JIJI::UserError, JIJI::ERROR_ILLEGAL_NAME ) {
        @dao.put( path, "test." )
      }
    }
    #親ディレクトリが存在しない
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.put( "not_found/test", "test." )
    }
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.put( "folder1/not_found/test", "test." )
    }

    #親ディレクトリがファイル
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.put( "file1/test", "test." )
    }

    #フォルダがすでに存在する
    assert_raise( JIJI::UserError, JIJI::ERROR_IS_NOT_FILE ) {
      @dao.put( "folder1", "test." )
    }
  end

  #ファイル作成の異常系のテスト
  def test_error_add
    #パスが不正
    ILLEGAL_PATHS.each {|path|
      assert_raise( JIJI::UserError, JIJI::ERROR_ILLEGAL_NAME ) {
        @dao.add( path, "test." )
      }
    }
    #親ディレクトリが存在しない
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.add( "not_found/test", "test." )
    }
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.add( "folder1/not_found/test", "test." )
    }

    #親ディレクトリがファイル
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.add( "file1/test", "test." )
    }

    #ファイルがすでに存在する
    assert_raise( JIJI::UserError, JIJI::ERROR_ALREADY_EXIST ) {
      @dao.add( "folder1", "test." )
    }
    #フォルダがすでに存在する
    assert_raise( JIJI::UserError, JIJI::ERROR_ALREADY_EXIST ) {
      @dao.add( "folder1", "test." )
    }
  end

  #フォルダ作成の異常系のテスト
  def test_error_mkcol
    #パスが不正
    ILLEGAL_PATHS.each {|path|
      assert_raise( JIJI::UserError, JIJI::ERROR_ILLEGAL_NAME ) {
        @dao.mkcol( path )
      }
    }
    #親ディレクトリが存在しない
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.mkcol( "not_found/test" )
    }
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.mkcol( "folder1/not_found/test" )
    }

    #親ディレクトリがファイル
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.mkcol( "file1/test" )
    }

    #フォルダがすでに存在する
    assert_raise( JIJI::UserError, JIJI::ERROR_ALREADY_EXIST ) {
      @dao.mkcol( "folder1" )
    }
    #ファイルがすでに存在する
    assert_raise( JIJI::UserError, JIJI::ERROR_ALREADY_EXIST ) {
      @dao.mkcol( "file1" )
    }
  end

  #削除の異常系のテスト
  def test_error_delete
    #パスが不正
    ILLEGAL_PATHS.each {|path|
      assert_raise( JIJI::UserError, JIJI::ERROR_ILLEGAL_NAME ) {
        @dao.delete( path )
      }
    }
    #対象が存在しない
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.delete( "not_found" )
    }
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.delete( "folder1/not_found" )
    }
  end

  #コピーの異常系のテスト
  def test_error_copy
    #パスが不正
    ILLEGAL_PATHS.each {|path|
      assert_raise( JIJI::UserError, JIJI::ERROR_ILLEGAL_NAME ) {
        @dao.copy( path, "test" )
      }
      assert_raise( JIJI::UserError, JIJI::ERROR_ILLEGAL_NAME ) {
        @dao.copy( "file1", path )
      }
    }
    #対象が存在しない
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.copy( "not_found", "folder1" )
    }
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.copy( "folder1/not_found", "folder1" )
    }
  end

  #移動の異常系のテスト
  def test_error_move
    #パスが不正
    ILLEGAL_PATHS.each {|path|
      assert_raise( JIJI::UserError, JIJI::ERROR_ILLEGAL_NAME ) {
        @dao.move( path, "test" )
      }
      assert_raise( JIJI::UserError, JIJI::ERROR_ILLEGAL_NAME ) {
        @dao.move( "file1", path )
      }
    }
    #対象が存在しない
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.move( "not_found", "folder1" )
    }
    assert_raise( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @dao.move( "folder1/not_found", "folder1" )
    }
  end

  def list( path="" )
    @dao.list(path).map {|item|
      assert_not_nil item[:update]
      assert_equals item[:path], path.empty? ? item[:name] : "#{path}/#{item[:name]}"
      "#{item[:name]}:#{item[:type]}"
    }
  end

  def list_r( path="" )
    @dao.list(path, true).map {|item|
      assert_not_nil item[:update]
      assert_equals item[:name], File.basename(item[:path])
      "#{item[:path]}:#{item[:type]}"
    }
  end

  def assert_raise( type, code )
    begin
      yield
      fail
    rescue type
      assert_equals $!.code, code
    end
  end

end