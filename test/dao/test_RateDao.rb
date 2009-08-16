#!/usr/bin/ruby

$: << "../lib"

require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/dao/rate_dao'
require 'fileutils'
require 'rubygems'
require 'test_utils'

class RateDaoTest <  RUNIT::TestCase

  include Test::Constants

  def setup
    @dir = File.dirname(__FILE__) + "/RateDaoTest.tmp"
    FileUtils.mkdir_p @dir

    @cd = JIJI::Dao::RateDao.new( @dir, [ "30s", "1m", "2m", "3h", "5d"] )
  end

  def teardown
    FileUtils.rm_rf @dir
  end

  def test_basic

    pair_infos = {
      :USDJPY => Info.new( 10000 ),
      :AUDUSD => Info.new( 10000 )
    }

    # 書き込み
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.0, 100.05, -200, 200 ),
      :AUDUSD => JIJI::Rate.new( 100.0, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 0) ))

    # データはまだない。
    key = Struct.new( :scale, :pair )
    expected = {
      key.new( "30s", :USDJPY )=>[], key.new( "1m", :USDJPY )=>[],
      key.new( "2m",  :USDJPY )=>[], key.new( "3h", :USDJPY )=>[],
      key.new( "5d",  :USDJPY )=>[], key.new( "1w", :USDJPY )=>[],
      key.new( "30s", :AUDUSD )=>[], key.new( "1m", :AUDUSD )=>[],
      key.new( "2m",  :AUDUSD )=>[], key.new( "3h", :AUDUSD )=>[],
      key.new( "5d",  :AUDUSD )=>[], key.new( "1w", :AUDUSD )=>[]
    }
    assert_saved_data expected

    # 10s後 : データはまだ追加されない
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 101.0, 101.05, -250, 250 ),
      :AUDUSD => JIJI::Rate.new( 101.0, 101.05, -250, 250 )
    }, Time.local(2008, 8, 1, 10, 0, 10) ))
    assert_saved_data expected

    # 40s後 : 30sにデータが追加される
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 105.0, 105.05, -190, 190 ),
      :AUDUSD => JIJI::Rate.new( 105.0, 105.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 40) ))

    expected[key.new("30s", :USDJPY)] << ["100.0","105.0","105.0","100.0",
       "100.05","105.05","105.05","100.05",
       "-200.0", "-190.0", "-190.0", "-250.0",
       "200.0", "190.0", "250.0", "190.0",
       Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 0, 30).to_i.to_s]
    expected[key.new("30s", :AUDUSD)] << ["100.0","105.0","105.0","100.0",
       "100.05","105.05","105.05","100.05",
       "-200.0", "-200.0", "-200.0", "-250.0",
       "200.0", "200.0", "250.0", "200.0",
       Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 0, 30).to_i.to_s]

    assert_saved_data expected

    # 1m 20s後
    # 30s : ストックなしで30秒後のデータが送られてきた →　データがそのまま追加される
    # 1m : データが追加される
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 103.0, 103.05, -210, 210 ),
      :AUDUSD => JIJI::Rate.new( 103.0, 103.05, -210, 210 )
    }, Time.local(2008, 8, 1, 10, 1, 20) ))

    expected[key.new("30s", :USDJPY)] << ["103.0","103.0","103.0","103.0",
       "103.05","103.05","103.05","103.05",
       "-210.0", "-210.0", "-210.0", "-210.0",
       "210.0", "210.0", "210.0", "210.0",
       Time.local(2008, 8, 1, 10, 0, 30).to_i.to_s, Time.local(2008, 8, 1, 10, 1, 0).to_i.to_s]
    expected[key.new("30s", :AUDUSD)] <<  ["103.0","103.0","103.0","103.0",
       "103.05","103.05","103.05","103.05",
       "-210.0", "-210.0", "-210.0", "-210.0",
       "210.0", "210.0", "210.0", "210.0",
       Time.local(2008, 8, 1, 10, 0, 30).to_i.to_s, Time.local(2008, 8, 1, 10, 1, 0).to_i.to_s]

    expected[key.new("1m", :USDJPY)] << ["100.0","103.0","105.0","100.0",
       "100.05","103.05","105.05","100.05",
       "-200.0", "-210.0", "-190.0", "-250.0",
       "200.0", "210.0", "250.0", "190.0",
       Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 1, 0).to_i.to_s]
    expected[key.new("1m", :AUDUSD)] << ["100.0","103.0","105.0","100.0",
       "100.05","103.05","105.05","100.05",
       "-200.0", "-210.0", "-200.0", "-250.0",
       "200.0", "210.0", "250.0", "200.0",
       Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 1, 0).to_i.to_s]

    assert_saved_data expected


    # さらにデータを追加
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.0, 100.05, -200, 200 ),
      :AUDUSD => JIJI::Rate.new( 100.0, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 1, 30) ))
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 103.0, 103.05, -210, 210 ),
      :AUDUSD => JIJI::Rate.new( 103.0, 103.05, -210, 210 )
    }, Time.local(2008, 8, 1, 10, 1, 50) ))
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 101.0, 101.05, -250, 250 ),
      :AUDUSD => JIJI::Rate.new( 101.0, 101.05, -250, 250 )
    }, Time.local(2008, 8, 1, 10, 2, 30) ))

    expected[key.new("30s", :USDJPY)] << ["100.0","100.0","100.0","100.0",
       "100.05","100.05","100.05","100.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 10, 1, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 1, 30).to_i.to_s]
    expected[key.new("30s", :AUDUSD)] <<  ["100.0","100.0","100.0","100.0",
      "100.05","100.05","100.05","100.05",
      "-200.0", "-200.0", "-200.0", "-200.0",
      "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 10, 1, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 1, 30).to_i.to_s]

    expected[key.new("30s", :USDJPY)] << ["103.0","101.0","103.0","101.0",
       "103.05","101.05","103.05","101.05",
       "-210.0", "-250.0", "-210.0", "-250.0",
       "210.0", "250.0", "250.0", "210.0",
       Time.local(2008, 8, 1, 10, 1, 30).to_i.to_s, Time.local(2008, 8, 1, 10, 2, 0).to_i.to_s]
    expected[key.new("30s", :AUDUSD)] << ["103.0","101.0","103.0","101.0",
      "103.05","101.05","103.05","101.05",
      "-210.0", "-250.0", "-210.0", "-250.0",
      "210.0", "250.0", "250.0", "210.0",
       Time.local(2008, 8, 1, 10, 1, 30).to_i.to_s, Time.local(2008, 8, 1, 10, 2, 0).to_i.to_s]

    expected[key.new("1m", :USDJPY)] << ["100.0","101.0","103.0","100.0",
       "100.05","101.05","103.05","100.05",
       "-200.0", "-250.0", "-200.0", "-250.0",
       "200.0", "250.0", "250.0", "200.0",
       Time.local(2008, 8, 1, 10, 1, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 2, 0).to_i.to_s]
    expected[key.new("1m", :AUDUSD)] <<  ["100.0","101.0","103.0","100.0",
       "100.05","101.05","103.05","100.05",
       "-200.0", "-250.0", "-200.0", "-250.0",
       "200.0", "250.0", "250.0", "200.0",
       Time.local(2008, 8, 1, 10, 1, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 2, 0).to_i.to_s]

    expected[key.new("2m", :USDJPY)] << ["100.0","101.0","105.0","100.0",
       "100.05","101.05","105.05","100.05",
       "-200.0", "-250.0", "-190.0", "-250.0",
       "200.0", "250.0", "250.0", "190.0",
       Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 2, 0).to_i.to_s]
    expected[key.new("2m", :AUDUSD)] <<  ["100.0","101.0","105.0","100.0",
       "100.05","101.05","105.05","100.05",
       "-200.0", "-250.0", "-200.0", "-250.0",
       "200.0", "250.0", "250.0", "200.0",
       Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 2, 0).to_i.to_s]

    assert_saved_data expected


    # さらにデータを追加
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.0, 100.05, -200, 200 ),
      :AUDUSD => JIJI::Rate.new( 100.0, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 15, 1, 30) ))

    expected[key.new("30s", :USDJPY)] << ["100.0","100.0","100.0","100.0",
       "100.05","100.05","100.05","100.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 10, 2, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 3, 0).to_i.to_s]
    expected[key.new("30s", :AUDUSD)] <<  ["100.0","100.0","100.0","100.0",
       "100.05","100.05","100.05","100.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 10, 2, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 3, 0).to_i.to_s]

    expected[key.new("1m", :USDJPY)] << ["100.0","100.0","100.0","100.0",
       "100.05","100.05","100.05","100.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 10, 2, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 3, 0).to_i.to_s]
    expected[key.new("1m", :AUDUSD)] <<  ["100.0","100.0","100.0","100.0",
       "100.05","100.05","100.05","100.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 10, 2, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 3, 0).to_i.to_s]

    expected[key.new("2m", :USDJPY)] << ["100.0","100.0","100.0","100.0",
       "100.05","100.05","100.05","100.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 10, 2, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 4, 0).to_i.to_s]
    expected[key.new("2m", :AUDUSD)] << ["100.0","100.0","100.0","100.0",
       "100.05","100.05","100.05","100.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 10, 2, 0).to_i.to_s, Time.local(2008, 8, 1, 10, 4, 0).to_i.to_s]

    expected[key.new("3h", :USDJPY)] << ["100.0","100.0","105.0","100.0",
       "100.05","100.05","105.05","100.05",
       "-200.0", "-200.0", "-190.0", "-250.0",
       "200.0", "200.0", "250.0", "190.0",
       Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s, Time.local(2008, 8, 1, 12, 0, 0).to_i.to_s]
    expected[key.new("3h", :AUDUSD)] <<  ["100.0","100.0","105.0","100.0",
       "100.05","100.05","105.05","100.05",
       "-200.0", "-200.0", "-200.0", "-250.0",
       "200.0", "200.0", "250.0", "200.0",
       Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s, Time.local(2008, 8, 1, 12, 0, 0).to_i.to_s]

    assert_saved_data expected


    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.0, 102.05, -200, 200 ),
      :AUDUSD => JIJI::Rate.new( 100.0, 100.05, -200, 200 )
    }, Time.local(2008, 8, 7, 15, 1, 30) ))
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.0, 102.05, -200, 200 ),
      :AUDUSD => JIJI::Rate.new( 100.0, 100.05, -200, 200 )
    }, Time.local(2008, 8, 7, 15, 2, 0) ))


    expected[key.new("30s", :USDJPY)] << ["100.0","100.0","100.0","100.0",
       "102.05","102.05","102.05","102.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 10, 3, 0).to_i.to_s, Time.local(2008, 8, 1, 15, 2, 0).to_i.to_s]
    expected[key.new("30s", :AUDUSD)] <<  ["100.0","100.0","100.0","100.0",
       "100.05","100.05","100.05","100.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 10, 3, 0).to_i.to_s, Time.local(2008, 8, 1, 15, 2, 0).to_i.to_s]
    expected[key.new("30s", :USDJPY)] << ["100.0","100.0","100.0","100.0",
       "102.05","102.05","102.05","102.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 15, 2, 0).to_i.to_s, Time.local(2008, 8, 7, 15, 2, 0).to_i.to_s]
    expected[key.new("30s", :AUDUSD)] <<  ["100.0","100.0","100.0","100.0",
       "100.05","100.05","100.05","100.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 15, 2, 0).to_i.to_s, Time.local(2008, 8, 7, 15, 2, 0).to_i.to_s]


    expected[key.new("1m", :USDJPY)] << ["100.0","100.0","100.0","100.0",
       "102.05","102.05","102.05","102.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 10, 3, 0).to_i.to_s, Time.local(2008, 8, 1, 15, 2, 0).to_i.to_s]
    expected[key.new("1m", :AUDUSD)] <<  ["100.0","100.0","100.0","100.0",
       "100.05","100.05","100.05","100.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 10, 3, 0).to_i.to_s, Time.local(2008, 8, 1, 15, 2, 0).to_i.to_s]
    expected[key.new("1m", :USDJPY)] << ["100.0","100.0","100.0","100.0",
       "102.05","102.05","102.05","102.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 15, 2, 0).to_i.to_s, Time.local(2008, 8, 7, 15, 2, 0).to_i.to_s]
    expected[key.new("1m", :AUDUSD)] <<  ["100.0","100.0","100.0","100.0",
       "100.05","100.05","100.05","100.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 15, 2, 0).to_i.to_s, Time.local(2008, 8, 7, 15, 2, 0).to_i.to_s]

	  expected[key.new("2m", :USDJPY)] << ["100.0","100.0","100.0","100.0",
	     "102.05","102.05","102.05","102.05",
	     "-200.0", "-200.0", "-200.0", "-200.0",
	     "200.0", "200.0", "200.0", "200.0",
	     Time.local(2008, 8, 1, 10, 4, 0).to_i.to_s, Time.local(2008, 8, 1, 15, 2, 0).to_i.to_s]
	  expected[key.new("2m", :AUDUSD)] <<  ["100.0","100.0","100.0","100.0",
	     "100.05","100.05","100.05","100.05",
	     "-200.0", "-200.0", "-200.0", "-200.0",
	     "200.0", "200.0", "200.0", "200.0",
	     Time.local(2008, 8, 1, 10, 4, 0).to_i.to_s, Time.local(2008, 8, 1, 15, 2, 0).to_i.to_s]
    expected[key.new("2m", :USDJPY)] << ["100.0","100.0","100.0","100.0",
       "102.05","102.05","102.05","102.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 15, 2, 0).to_i.to_s, Time.local(2008, 8, 7, 15, 2, 0).to_i.to_s]
    expected[key.new("2m", :AUDUSD)] <<  ["100.0","100.0","100.0","100.0",
       "100.05","100.05","100.05","100.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 15, 2, 0).to_i.to_s, Time.local(2008, 8, 7, 15, 2, 0).to_i.to_s]

    expected[key.new("3h", :USDJPY)] << ["100.0","100.0","100.0","100.0",
       "102.05","102.05","102.05","102.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 12, 0, 0).to_i.to_s, Time.local(2008, 8, 1, 18, 0, 0).to_i.to_s]
    expected[key.new("3h", :AUDUSD)] <<  ["100.0","100.0","100.0","100.0",
       "100.05","100.05","100.05","100.05",
       "-200.0", "-200.0", "-200.0", "-200.0",
       "200.0", "200.0", "200.0", "200.0",
       Time.local(2008, 8, 1, 12, 0, 0).to_i.to_s, Time.local(2008, 8, 1, 18, 0, 0).to_i.to_s]

    expected[key.new("5d", :USDJPY)] << ["100.0","100.0","105.0","100.0",
       "100.05","102.05","105.05","100.05",
       "-200.0", "-200.0", "-190.0", "-250.0",
       "200.0", "200.0", "250.0", "190.0",
       Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s, Time.local(2008, 8, 4, 9, 0, 0).to_i.to_s]
    expected[key.new("5d", :AUDUSD)] <<  ["100.0","100.0","105.0","100.0",
       "100.05","100.05","105.05","100.05",
       "-200.0", "-200.0", "-200.0", "-250.0",
       "200.0", "200.0", "250.0", "200.0",
       Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s, Time.local(2008, 8, 4, 9, 0, 0).to_i.to_s]

    assert_saved_data expected


    # 範囲を指定して取得するテスト
    # 範囲指定あり : オーバー
    assert_equals read( "30s", :USDJPY, Time.local(2008, 7, 1, 0, 0, 0), Time.local(2008, 8, 18, 5, 1, 30) ),
                  expected[key.new("30s", :USDJPY)]

    # 範囲指定あり : 最大/最小内
    assert_equals read( "30s", :USDJPY, Time.local(2008, 8, 1, 10, 1, 20), Time.local(2008, 8, 7, 15, 1, 29) ),
                  expected[key.new("30s", :USDJPY)][2..-2]
    assert_equals read( "1m", :USDJPY, Time.local(2008, 8, 1, 10, 1, 20), Time.local(2008, 8, 7, 15, 1, 29) ),
                  expected[key.new("1m", :USDJPY)][1..-2]

    # 範囲指定あり : 期間が短く何も取得できない
    assert_equals read( "30s", :USDJPY, Time.local(2008, 8, 1, 10, 1, 31), Time.local(2008, 8, 1, 10, 1, 35) ), []
    assert_equals read( "30s", :USDJPY, Time.local(2008, 7, 1, 10, 1, 31), Time.local(2008, 7, 3, 10, 1, 35) ), []
    assert_equals read( "30s", :USDJPY, Time.local(2008, 9, 1, 10, 1, 31), Time.local(2008, 9, 1, 15, 1, 35) ), []


    # 開始日時のみ指定あり
    assert_equals read( "30s", :USDJPY, Time.local(2008, 8, 1, 10, 1, 20), nil ),
                  expected[key.new("30s", :USDJPY)][2..-1]

    # 終了日時のみ指定あり
    assert_equals read( "30s", :USDJPY, nil, Time.local(2008, 8, 7, 15, 1, 29) ),
                  expected[key.new("30s", :USDJPY)][0..-2]

    # 異常系
    # 存在しないペアのデータを取得
    assert_equals read( "30s", :NOT_FOUND ), []

    # 存在しないscaleのデータを取得
    assert_equals read( "11111s", :USD_JPY ), []

    # break
    i = 0
    list = []
    @cd.each( "30s", :USDJPY ) {|row|
      i+=1
      if (list.length < 1 )
        list << row
      else
        break
      end
    }
    assert_equals list.length, 1
    assert_equals i, 2

    # next
    i = 0
    list = []
    @cd.each( "30s", :USDJPY ) {|row|
      i+=1
      if (list.length < 1 )
        list << row
      else
        next
      end
    }
    assert_equals list.length, 1
    assert_equals i, 7

    # 全データ取得
    assert_equals read_all( "raw" ), [
      {
        :USDJPY =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s],
        :AUDUSD =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s]
      },
      {
        :USDJPY =>["101.0", "101.05", "-250.0", "250.0", Time.local(2008, 8, 1, 10, 0, 10).to_i.to_s],
        :AUDUSD =>["101.0", "101.05", "-250.0", "250.0", Time.local(2008, 8, 1, 10, 0, 10).to_i.to_s]
      },
      {
        :USDJPY =>["105.0", "105.05", "-190.0", "190.0", Time.local(2008, 8, 1, 10, 0, 40).to_i.to_s],
        :AUDUSD =>["105.0", "105.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 40).to_i.to_s]
      },
      {
        :USDJPY =>["103.0", "103.05", "-210.0", "210.0", Time.local(2008, 8, 1, 10, 1, 20).to_i.to_s],
        :AUDUSD =>["103.0", "103.05", "-210.0", "210.0", Time.local(2008, 8, 1, 10, 1, 20).to_i.to_s]
      },
      {
        :USDJPY =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 1, 30).to_i.to_s],
        :AUDUSD =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 1, 30).to_i.to_s]
      },
      {
        :USDJPY =>["103.0", "103.05", "-210.0", "210.0", Time.local(2008, 8, 1, 10, 1, 50).to_i.to_s],
        :AUDUSD =>["103.0", "103.05", "-210.0", "210.0", Time.local(2008, 8, 1, 10, 1, 50).to_i.to_s]
      },
      {
        :USDJPY =>["101.0", "101.05", "-250.0", "250.0", Time.local(2008, 8, 1, 10, 2, 30).to_i.to_s],
        :AUDUSD =>["101.0", "101.05", "-250.0", "250.0", Time.local(2008, 8, 1, 10, 2, 30).to_i.to_s]
      },
      {
        :USDJPY =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 15, 1, 30).to_i.to_s],
        :AUDUSD =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 15, 1, 30).to_i.to_s]
      },
      {
        :USDJPY =>["100.0", "102.05", "-200.0", "200.0", Time.local(2008, 8, 7, 15, 1, 30).to_i.to_s],
        :AUDUSD =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 7, 15, 1, 30).to_i.to_s]
      },
      {
        :USDJPY =>["100.0", "102.05", "-200.0", "200.0", Time.local(2008, 8, 7, 15, 2, 0).to_i.to_s],
        :AUDUSD =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 7, 15, 2, 0).to_i.to_s]
      }
    ]
    assert_equals read_all( "raw", Time.local(2008, 8, 1, 10, 0, 40), Time.local(2008, 8, 1, 15, 1, 20) ), [
      {
        :USDJPY =>["105.0", "105.05", "-190.0", "190.0", Time.local(2008, 8, 1, 10, 0, 40).to_i.to_s],
        :AUDUSD =>["105.0", "105.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 40).to_i.to_s]
      },
      {
        :USDJPY =>["103.0", "103.05", "-210.0", "210.0", Time.local(2008, 8, 1, 10, 1, 20).to_i.to_s],
        :AUDUSD =>["103.0", "103.05", "-210.0", "210.0", Time.local(2008, 8, 1, 10, 1, 20).to_i.to_s]
      },
      {
        :USDJPY =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 1, 30).to_i.to_s],
        :AUDUSD =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 1, 30).to_i.to_s]
      },
      {
        :USDJPY =>["103.0", "103.05", "-210.0", "210.0", Time.local(2008, 8, 1, 10, 1, 50).to_i.to_s],
        :AUDUSD =>["103.0", "103.05", "-210.0", "210.0", Time.local(2008, 8, 1, 10, 1, 50).to_i.to_s]
      },
      {
        :USDJPY =>["101.0", "101.05", "-250.0", "250.0", Time.local(2008, 8, 1, 10, 2, 30).to_i.to_s],
        :AUDUSD =>["101.0", "101.05", "-250.0", "250.0", Time.local(2008, 8, 1, 10, 2, 30).to_i.to_s]
      }
    ]
    # データがない
    assert_equals read_all( "raw", Time.local(2008, 12, 1, 10, 0, 40), Time.local(2008, 12, 3, 15, 1, 20) ), []

    # 別のスケール
    assert_equals read_all( "5d" ), [
      {
        :USDJPY => ["100.0","100.0","105.0","100.0",
           "100.05","102.05","105.05","100.05",
           "-200.0", "-200.0", "-190.0", "-250.0",
           "200.0", "200.0", "250.0", "190.0",
           Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s, Time.local(2008, 8, 4, 9, 0, 0).to_i.to_s],
        :AUDUSD =>["100.0","100.0","105.0","100.0",
           "100.05","100.05","105.05","100.05",
           "-200.0", "-200.0", "-200.0", "-250.0",
           "200.0", "200.0", "250.0", "200.0",
           Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s, Time.local(2008, 8, 4, 9, 0, 0).to_i.to_s]
      }
    ]

    # break
    i = 0
    list = []
    @cd.each_all_pair_rates( "30s" ) {|row|
      i+=1
      if (list.length < 1 )
        list << row
      else
        break
      end
    }
    assert_equals list.length, 1
    assert_equals i, 2

    # next
    i = 0
    list = []
    @cd.each_all_pair_rates( "30s" ) {|row|
      i+=1
      if (list.length < 1 )
        list << row
      else
        next
      end
    }
    assert_equals list.length, 1
    assert_equals i, 7

    assert_equals( @cd.dao(:USDJPY).first_time(:raw), 1217552400);
    assert_equals( @cd.dao(:USDJPY).last_time(:raw), 1218088920);

  end

  # 一部のデータが欠けている場合の一覧取得テスト
  def test_each_all_pair_rates__lack

    pair_infos = {
      :EURJPY => Info.new( 10000 ),
      :AUDUSD => Info.new( 10000 )
    }

    # 最初のデータがない
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.0, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 10) ))
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.1, 100.05, -200, 200 ),
      :AUDUSD => JIJI::Rate.new( 100.1, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 20) ))
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.2, 100.05, -200, 200 ),
      :AUDUSD => JIJI::Rate.new( 100.2, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 30) ))

    assert_equals read_all( "raw" ), [
      {
        :USDJPY =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 10).to_i.to_s],
      },
      {
        :USDJPY =>["100.1", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 20).to_i.to_s],
        :AUDUSD =>["100.1", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 20).to_i.to_s]
      },
      {
        :USDJPY =>["100.2", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 30).to_i.to_s],
        :AUDUSD =>["100.2", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 30).to_i.to_s]
      },
    ]
    FileUtils.rm_rf @dir


    # 途中のデータがない
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.0, 100.05, -200, 200 ),
      :AUDUSD => JIJI::Rate.new( 100.0, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 10) ))
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.1, 100.05, -200, 200 ),
    }, Time.local(2008, 8, 1, 10, 0, 20) ))
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.2, 100.05, -200, 200 ),
      :AUDUSD => JIJI::Rate.new( 100.2, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 30) ))

    assert_equals read_all( "raw" ), [
      {
        :USDJPY =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 10).to_i.to_s],
        :AUDUSD =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 10).to_i.to_s]
      },
      {
        :USDJPY =>["100.1", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 20).to_i.to_s],
      },
      {
        :USDJPY =>["100.2", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 30).to_i.to_s],
        :AUDUSD =>["100.2", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 30).to_i.to_s]
      },
    ]
    FileUtils.rm_rf @dir


    # 最後のデータがない
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.0, 100.05, -200, 200 ),
      :AUDUSD => JIJI::Rate.new( 100.0, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 10) ))
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.1, 100.05, -200, 200 ),
      :AUDUSD => JIJI::Rate.new( 100.1, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 20) ))
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.2, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 30) ))

    assert_equals read_all( "raw" ), [
      {
        :USDJPY =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 10).to_i.to_s],
        :AUDUSD =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 10).to_i.to_s]
      },
      {
        :USDJPY =>["100.1", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 20).to_i.to_s],
        :AUDUSD =>["100.1", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 20).to_i.to_s]
      },
      {
        :USDJPY =>["100.2", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 30).to_i.to_s],
      },
    ]
    FileUtils.rm_rf @dir


    # 最後のデータがない
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.0, 100.05, -200, 200 ),
      :AUDUSD => JIJI::Rate.new( 100.0, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 10) ))
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.1, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 20) ))
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.2, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 30) ))
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :AUDUSD => JIJI::Rate.new( 100.3, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 40) ))
    @cd.next_rates( JIJI::Rates.new( pair_infos, {
      :AUDUSD => JIJI::Rate.new( 100.4, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 50) ))

    assert_equals read_all( "raw" ), [
      {
        :USDJPY =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 10).to_i.to_s],
        :AUDUSD =>["100.0", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 10).to_i.to_s]
      },
      {
        :USDJPY =>["100.1", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 20).to_i.to_s]
      },
      {
        :USDJPY =>["100.2", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 30).to_i.to_s]
      },
      {
        :AUDUSD =>["100.3", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 40).to_i.to_s]
      },
      {
        :AUDUSD =>["100.4", "100.05", "-200.0", "200.0", Time.local(2008, 8, 1, 10, 0, 50).to_i.to_s]
      },
    ]

  end

  def test_pair_buffer
    buff = JIJI::Dao::RateDao::PairBuffer.new

    # 最初は空
    assert_equals buff.next?, false
    assert_nil buff.next

    # データを追加
    buff.add( "USDJPY", ["a",100] )
    buff.add( "EURJPY", ["b",100] )
    assert_equals buff.next?, true
    assert_equals buff.next, {
      :USDJPY=>["a",100], :EURJPY=>["b",100]
    }
    assert_equals buff.next?, false
    assert_nil buff.next

    # データを追加
    buff.add( "USDJPY", ["a",100] )
    buff.add( "EURJPY", ["b",101] )
    buff.add( "EURJPY", ["a",100] )
    buff.add( "AUDJPY", ["c",102] )
    assert_equals buff.next?, true
    assert_equals buff.next, {
      :USDJPY=>["a",100], :EURJPY=>["a",100]
    }
    assert_equals buff.next?, true
    assert_equals buff.next, {
      :EURJPY=>["b",101]
    }
    assert_equals buff.next?, true
    assert_equals buff.next, {
      :AUDJPY=>["c",102]
    }
    assert_equals buff.next?, false
    assert_nil buff.next
  end

  def assert_saved_data( expected )
    expected.each_pair {|k,v|
      begin
        assert_equals read( k.scale, k.pair ), v
      rescue
        puts k.scale + ":" + k.pair.to_s
        raise $!
      end
    }
  end

  def read( scale, pair, start_date=nil, end_date=nil )
    list = []
    @cd.each( scale, pair, start_date, end_date ) {|row| list << row }
    return list
  end

  def read_all( scale, start_date=nil, end_date=nil )
    list = []
    @cd.each_all_pair_rates( scale, start_date, end_date ) {|row| list << row }
    return list
  end
end