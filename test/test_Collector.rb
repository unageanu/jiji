#!/usr/bin/ruby

$: << "../lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/configuration'
require 'jiji/collector'
require 'jiji/operator'
require 'jiji/observer'
require 'jiji/dao/rate_dao'
require 'test_utils'
require 'logger'
require 'csv'

# JIJI::Collectorのテスト
class CollectorTest <  RUNIT::TestCase

  include Test::Constants

  # 前準備
  def setup
    @dir = File.dirname(__FILE__) + "/CollectorTest.tmp"
    FileUtils.rm_rf @dir if File.exist?( @dir )
    FileUtils.mkdir_p @dir

    @logger = Logger.new STDOUT
    @client = Test::MockClient.new

    @c = JIJI::Collector.new
    @c.logger = @logger
    @c.conf = CONF
    @c.client = @client
  end

  # 後始末
  def teardown
    FileUtils.rm_rf @dir
  end

  #基本操作のテスト。
  def test_basic
    observer_manager = nil
    begin
      rate_dao = JIJI::Dao::RateDao.new(@dir, ["5s","1m"])
      observer_manager = JIJI::WorkerThreadObserverManager.new([
        rate_dao
      ], @logger)
      class << observer_manager
        def threads
          @workers.map { |w| w.thread }
        end
      end
      @c.observer_manager = observer_manager

      # スレッドが動作していることを確認。
      observer_manager.threads.each {|t|
        assert_equals t.status, "sleep"
      }

      assert_equals @c.progress, 0
      assert_equals @c.state, :WAITING

      # 取得開始
      @c.start
      assert_equals @c.progress, 0 # 進捗は常に0
      assert_equals @c.state, :RUNNING

      # しばらくまって
      sleep 20
      assert_equals @c.progress, 0 # 進捗は常に0
      assert_equals @c.state, :RUNNING

      # ログファイルが作成されていればOK
      date = Time.now.strftime("%Y-%m-%d")

      count = 0
      CSV.open("#{@dir}/EURJPY/raw/#{date}.csv", 'r') {|row|
        assert_equals row.length, 6
        count += 1
      }
      assert_equals count > 0, true

      count = 0
      CSV.open("#{@dir}/EURJPY/5s/#{date}.csv", 'r') {|row|
        assert_equals row.length, 19
        count += 1
      }
      assert_equals count > 0, true

    ensure
      @c.stop

      assert_equals @c.progress, 0 # 進捗は常に0
      assert_equals @c.state, :CANCELED

      # オブザーバーも停止していることを確認
      # スレッドが停止していることを確認。
      if observer_manager
        observer_manager.threads.each {|t|
          assert_equals t.status, false
        }
      end
    end
  end

  #ObserverManagerへの通知でエラーとなった場合のテスト。
  #エラーがログに保存された上で処理は継続
  def test_error_ObserverManager
    begin
      observer_manager = Object.new
      class << observer_manager
        def next_rates( rate )
          raise "test."
        end
        def stop
          @stopped = true
        end
        def stopped?
          @stopped
        end
      end
      @c.observer_manager = observer_manager

      assert_equals @c.progress, 0
      assert_equals @c.state, :WAITING

      # 取得開始
      @c.start
      assert_equals @c.state, :RUNNING

      # しばらくまって
      sleep 5
      assert_equals @c.state, :RUNNING # エラーになっていても動作し続ける
      assert_equals observer_manager.stopped?, nil

    ensure
      @c.stop

      assert_equals @c.state, :CANCELED
      assert_equals observer_manager.stopped?, true # オブザーバーも停止していることを確認

    end
  end

  #通貨ペアの情報取得でエラーとなった場合のテスト。
  #エラーがログに通知され、即座にキャンセルとなる。
  def test_error_GetPairInfo
    begin
      observer_manager = Object.new
      class << observer_manager
        def next_rates( rate );end
        def stop
          @stopped = true
        end
        def stopped?
          @stopped
        end
      end
      @c.observer_manager = observer_manager

      # リクエストの送付でエラーになる。
      class << @c.client
        def list_pairs
          raise "test  list_rates ."
        end
      end

      assert_equals @c.progress, 0
      assert_equals @c.state, :WAITING

      # 取得開始
      @c.start

      # しばらくまって
      sleep 5
      assert_equals @c.state, :ERROR_END # エラーになった場合、即終了
      assert_equals observer_manager.stopped?, true

    ensure
      @c.stop
    end
  end

  #レートの取得でエラーとなった場合のテスト。
  #エラーがログに通知された上で処理は続行。
  def test_error_GetRate
    begin
      observer_manager = Object.new
      class << observer_manager
        def next_rates( rate );end
        def stop
          @stopped = true
        end
        def stopped?
          @stopped
        end
      end
      @c.observer_manager = observer_manager

      # レートの取得でエラーになる。
      class << @c.client
        def list_rates
          raise "test  list_rates ."
        end
      end

      assert_equals @c.progress, 0
      assert_equals @c.state, :WAITING

      # 取得開始
      @c.start
      assert_equals @c.state, :RUNNING

      # しばらくまって
      sleep 5
      assert_equals @c.state, :RUNNING # エラーになっていても動作し続ける
      assert_equals observer_manager.stopped?, nil

    ensure
      @c.stop

      assert_equals @c.state, :CANCELED
      assert_equals observer_manager.stopped?, true # オブザーバーも停止していることを確認

    end
  end

end