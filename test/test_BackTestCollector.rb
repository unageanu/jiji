#!/usr/bin/ruby

$: << "../lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/configuration'
require 'jiji/collector'
require 'jiji/operator'
require 'jiji/observer'
require 'jiji/plugin/securities_plugin'
require 'test_utils'
require 'logger'
require 'csv'
require 'date'

#BackTestCollectorのテスト
#TODO 異常系のテスト
class BackTestCollectorTest <  RUNIT::TestCase

  include Test::Constants

  # 前準備
  def setup
    @dir = File.dirname(__FILE__) + "/BackCollectorTest"

    @logger = Logger.new STDOUT
    @client = Test::MockClient.new
    @rate_dao = JIJI::Dao::RateDao.new( @dir )
  end

  # 後始末
  def teardown
  end

  # 通常のログを使ったテスト
  def test_basic

    # 指定範囲
    # 存在するデータを内包する値を指定
    start_date = Time.local( 2008, 8, 4, 20, 50, 0)
    end_date   = Time.local( 2008, 8, 8, 23, 59, 50)
    c = create_collector( "#{@dir}/basic", start_date, end_date )
    log = run_collector( c )

    assert_rates log, TIMES_ALL

    # 存在するデータの一定範囲を指定
    start_date = Time.local( 2008, 8, 5, 23, 59, 40)
    end_date   = Time.local( 2008, 8, 6, 22, 59, 29)
    c = create_collector( "#{@dir}/basic", start_date, end_date )
    log = run_collector( c )

    assert_rates log, [
      Time.local( 2008,8,5,23,59,41),Time.local( 2008,8,5,23,59,51),
      Time.local( 2008,8,6,21,58,56),Time.local( 2008,8,6,22,59,20)
    ]

    # 開始日時がnull
    end_date   = Time.local( 2008, 8, 6, 0, 0, 0)
    c = create_collector( "#{@dir}/basic", nil, end_date )
    log = run_collector( c )

    assert_rates log, TIMES_04+TIMES_05


    # 終了日時がnull
    start_date   = Time.local( 2008, 8, 5, 23, 59, 50)
    c = create_collector( "#{@dir}/basic", start_date, nil )
    log = run_collector( c )

    assert_rates log, [Time.local( 2008,8,5,23,59,51)]+TIMES_06+TIMES_07


    # 開始終了ともにnull
    c = create_collector( "#{@dir}/basic", nil, nil )
    log = run_collector( c )

    assert_rates log, TIMES_ALL

    # データがない
    start_date = Time.local( 2008, 9, 5, 23, 59, 40)
    end_date   = Time.local( 2008, 10, 6, 22, 59, 29)
    c = create_collector( "#{@dir}/basic", start_date, end_date )
    log = run_collector( c )
    assert_equals c.state, :FINISHED

    assert_rates log, []

    # 途中でキャンセル
    start_date = Time.local( 2008, 7, 5, 23, 59, 40)
    end_date   = Time.local( 2008, 10, 6, 22, 59, 29)
    c = create_collector( "#{@dir}/basic", start_date, end_date )
    assert_equals c.state, :WAITING
    c.start
    c.stop
    sleep 0.1 while c.state == :RUNNING
    assert_equals c.state, :CANCELED

  end

  # 途中に抜けがあるログを使ったテスト
  def test_lack

    c = create_collector( "#{@dir}/lack", nil, nil )
    log = run_collector( c )

    assert_rates log, TIMES_04+TIMES_06+TIMES_07
  end

  #ObserverManagerへの通知でエラーとなった場合のテスト。
  #エラーがログに通知され、即座にキャンセルとなる。
  def test_error_ObserverManager

    c = create_collector( "#{@dir}/basic", nil, nil )
    begin
      # エラーが発生するようにカスタマイズ
      class << c.observer_manager
        def next_rates( rate )
          raise "test."
        end
      end

      assert_equals c.progress, 0
      assert_equals c.state, :WAITING

      # 取得開始
      c.start

      sleep 5
      assert_equals c.state, :ERROR_END # エラーになった場合、即終了
      assert_equals c.observer_manager.stopped, true # 停止もされる。

    ensure
      c.stop
    end
  end

  #通貨ペアの情報取得でエラーとなった場合のテスト。
  #エラーがログに通知され、即座にキャンセルとなる。
  def test_error_GetPairInfo

    c = create_collector( "#{@dir}/basic", nil, nil )
    begin

      # リクエストの送付でエラーになる。
      class << c.client
        def list_pairs
          raise "test  list_rates ."
        end
      end

      assert_equals c.progress, 0
      assert_equals c.state, :WAITING

      # 取得開始
      c.start

      sleep 5
      assert_equals c.state, :ERROR_END # エラーになった場合、即終了
      assert_equals c.observer_manager.stopped, true # 停止もされる。

    ensure
      c.stop
    end
  end

  #レートの取得でエラーとなった場合のテスト。
  #エラーがログに通知され、即座にキャンセルとなる。
  def test_error_GetRate

    c = create_collector( "#{@dir}/basic", nil, nil )
    begin

      # レートの取得でエラーになる。
      class << c.dao
        def each_all_pair_rates
          raise "test  each_all_pair_rates ."
        end
      end

      assert_equals c.progress, 0
      assert_equals c.state, :WAITING

      # 取得開始
      c.start

      sleep 10
      assert_equals c.state, :ERROR_END # エラーになった場合、即終了
      assert_equals c.observer_manager.stopped, true # 停止もされる。

    ensure
      c.stop
    end
  end


  def create_collector( dir, start_date, end_date )
    c = JIJI::BackTestCollector.new( JIJI::Dao::RateDao.new( dir ), start_date, end_date )
    c.logger = @logger
    c.observer_manager = DummyObserverManager.new
    c.conf = CONF
    c.client = @client
    c
  end

  def assert_rates( log, times )
    assert_equals log.length, times.length
    index = 0
    log.each {|rates|
      assert_not_nil rates.pair_infos
      assert_equals rates.time, times[index]
      assert_equals rates[:AUDJPY], JIJI::Rate.new( 100.73, 100.78, -189.0, 185.0, rates.time )
      assert_equals rates[:USDJPY], JIJI::Rate.new( 108.0, 108.01, -65.0, 61.0, rates.time )
      assert_equals rates[:ZARJPY], JIJI::Rate.new( 14.88, 14.92, -450.0, 420.0, rates.time )
      index += 1
    }
  end

  def run_collector( collector )
    assert_equals collector.state, :WAITING
    assert_equals collector.progress, 0
    collector.start
    assert_equals collector.state, :RUNNING
    i=0
    while collector.state != :FINISHED && i <= 100
      puts "prgress : #{collector.progress}"
      sleep 0.1
      i+=1
    end
    assert_equals collector.progress, 100
    collector.observer_manager.log
  end

  TIMES_04 =  [
    Time.local( 2008,8,4,21,58,56),Time.local( 2008,8,4,22,59,20),
	  Time.local( 2008,8,4,23,59,30),Time.local( 2008,8,4,23,59,41),
	  Time.local( 2008,8,4,23,59,51)
	]
  TIMES_05 =  [
    Time.local( 2008,8,5,21,58,56),Time.local( 2008,8,5,22,59,20),
    Time.local( 2008,8,5,23,59,30),Time.local( 2008,8,5,23,59,41),
    Time.local( 2008,8,5,23,59,51)
  ]
  TIMES_06 =  [
    Time.local( 2008,8,6,21,58,56),Time.local( 2008,8,6,22,59,20),
    Time.local( 2008,8,6,23,59,30),Time.local( 2008,8,6,23,59,41),
    Time.local( 2008,8,6,23,59,51)
  ]
  TIMES_07 =  [
    Time.local( 2008,8,7,21,58,56),Time.local( 2008,8,7,22,59,20),
    Time.local( 2008,8,7,23,59,30),Time.local( 2008,8,7,23,59,41),
    Time.local( 2008,8,7,23,59,51)
  ]
  TIMES_ALL = TIMES_04 + TIMES_05 + TIMES_06 + TIMES_07

end

class DummyObserverManager
  def initialize
    @log = []
    @stopped = false
  end
  def next_rates( rates )
    @log << rates
  end
  def stop
    @stopped = true
  end
  attr :log, true
  attr :stopped, true
end