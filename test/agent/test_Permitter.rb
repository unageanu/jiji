#!/usr/bin/ruby

$: << "../lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/agent/agent'
require 'jiji/agent/agent_manager'
require 'jiji/agent/agent_registry'
require 'jiji/agent/permitter'
require 'jiji/agent/util'
require 'jiji/configuration'
require 'jiji/collector'
require 'fileutils'
require 'test_utils'
require 'logger'

# Permitter のテスト
class PermitterTest <  RUNIT::TestCase

  include JIJI::AgentUtil
  include Test::Constants

  def setup
    @dir = File.dirname(__FILE__) + "/PermitterTest"
    FileUtils.mkdir_p @dir

    @logger = Logger.new STDOUT
    @registry = JIJI::AgentRegistry.new( "#{@dir}/agents", "#{@dir}/shared" )
    @registry.conf = CONF

    @r = JIJI::Permitter.new(5, 2)
  end

  def teardown
    @r.close
    FileUtils.rm_rf @dir
  end

  # 基本動作のテスト
  def test_basic

    untaint = UntaintClass.new

    # 汚染されたクラスのインスタンスを生成
    PermitterTestTaint.taint
    test = safe(4) {
      str =<<-STR
      class TaintClass
        def test(args)
          return args.test("a")
        end
        def test2(args)
          return args.test2("a")
        end
      end
      STR
      PermitterTestTaint.module_eval(str)
      PermitterTestTaint::TaintClass.new
    }

    # test.testはセーフレベル4で実行されるため、
    # untaint内のFile.exist?でセキュリティエラーになる
    begin
      safe(1) {
	      test.test untaint
	      fail
      }
    rescue SecurityError
    end

    # プロキシをはさむ
    with_proxy = @r.proxy( untaint, [/^test$/] )
    # 実行できるようになる
    assert_equals "ab", safe(4) {
      test.test( with_proxy )
    }
    # 許可されていないメソッドは使えない
    begin
      safe(4) {
        test.test2( with_proxy )
        fail
      }
    rescue SecurityError
    end

    # 例外を返すパターン
    with_proxy2 = @r.proxy( UntaintClass2.new, [/^test$/] )
    safe(4) {
      begin
        test.test( with_proxy2 )
        fail
      rescue IOError
      end
    }
    with_proxy3 = @r.proxy( UntaintClass3.new, [/^test$/] )
    safe(4) {
      begin
        test.test( with_proxy3 )
        fail
      rescue LoadError
      end
    }
  end

  # 戻り値にプロキシを適用するテスト
  def test_proxy_result
    untaint = UntaintClass.new

    # 汚染されたクラスのインスタンスを生成
    PermitterTestTaint.taint
    test = safe(4) {
      str =<<-STR
      class TaintClass2
        def test(args)
          result = args.return_value
          result.test("x")
        end
      end
      STR
      PermitterTestTaint.module_eval(str)
      PermitterTestTaint::TaintClass2.new
    }

    # プロキシをはさむ
    with_proxy = @r.proxy( untaint, [/^(return\_value|test)$/], [/^return\_value$/] )
    assert_equals "xb", safe(4) {
      test.test( with_proxy )
    }

    # 戻り値に適用されていない場合は実行できない
    untaint = UntaintClass.new
    with_proxy = @r.proxy( untaint, [/^(return_value|test)$/] )
    begin
      safe(4) {
        test.test with_proxy
        fail
      }
    rescue SecurityError
    end
  end

  # セーフレベルの高い環境で、プロキシを使ってみるテスト
  def test_use_proxy_in_safe4


    # 汚染されたクラスのインスタンスを生成
    PermitterTestTaint.taint
    test = safe(4) {
      str =<<-STR
      class Foo
        def test
          File.exist? "./test"
        end
      end
      class TaintClass3
        def test(req)
          # プロキシを設定して、セーフレベルを下げて実行しようとする
          req.proxy( Foo.new, [/.*/] ).test
        end
      end
      STR
      PermitterTestTaint.module_eval(str)
      PermitterTestTaint::TaintClass3.new
    }

    # エラーになるのを確認
    safe(4) {
      begin
        test.test(@r)
        fail
      rescue SecurityError
      end
    }
  end

end

class UntaintClass
  def test(args)
#

    # 汚れたクラスのインスタンス内で作成されたオブジェクトは汚染されている。
    # そのままではFile.exist?などの引数としては使えないので、必要に応じて
    # 安全性をチェックした後untaintすること。
    begin
      File.exist? args
      raise "fail"
    rescue SecurityError
    end
    # untaintすれば引数にできる
    File.exist? args.untaint
    return args + "b"
  end
  def test2(args)
    File.exist? "./test"
    return args + "b"
  end
  def return_value
    File.exist? "./test"
    return UntaintClass.new
  end
end
class UntaintClass2
  def test(args)
    raise IOError.new
  end
end
class UntaintClass3
  def test(args)
    raise LoadError.new
  end
end

module PermitterTestTaint
end