#!/usr/bin/ruby

$: << "../lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/dao/trade_result_dao'
require 'jiji/operator'
require 'fileutils'
require 'rubygems'
require 'test_utils'

class TradeResultDaoTest <  RUNIT::TestCase

  include Test::Constants

  def setup
    @dir = File.dirname(__FILE__) + "/TradeResultDaoTest.tmp"
    FileUtils.mkdir_p @dir

    @dao = JIJI::Dao::TradeResultDao.new( @dir, [ "30s", "1m", "5m" ] )
  end

  def teardown
    FileUtils.rm_rf @dir
  end

  def test_basic

    pair_infos = {
      :USDJPY => Info.new( 10000 ),
      :AUDUSD => Info.new( 10000 )
    }

    op = JIJI::Operator.new @dao
    op.conf = CONF
    op.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 101.0, 101.05, -250, 250 ),
      :AUDUSD => JIJI::Rate.new( 101.0, 101.05, -250, 250 )
    }, Time.local(2008,8,7,0,0,0)))

    assert_equals @dao.list_positions("30s"), {}
    assert_equals read_profit_or_loss("30s"), []
    assert_equals @dao.list_positions("1m"), {}
    assert_equals read_profit_or_loss("1m"), []

    op.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 101.03, 101.08, -250, 250 ),
      :AUDUSD => JIJI::Rate.new( 101.03, 101.08, -250, 250 )
    }, Time.local(2008,8,7,0,0,40)))

    assert_equals @dao.list_positions("30s"), {}
    assert_equals read_profit_or_loss("30s"), [
      ["0", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,30).to_i.to_s]
    ]
    assert_equals @dao.list_positions("1m"), {}
    assert_equals read_profit_or_loss("1m"), []

    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,0,50)), {}
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,0,50)), {}
    
    # 注文
    p1 = op.buy( 1, :USDJPY, "a" )
    op.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 101.0, 101.05, -250, 250 ),
      :AUDUSD => JIJI::Rate.new( 101.0, 101.05, -250, 250 )
    }, Time.local(2008,8,7,0,1,1)  ))

    p1_props = {
       :count=>1,
       :rate=>101.08,
       :state=>1,
       :fix_rate=>nil,
       :date=>1218034840,
       :pair=>:USDJPY,
       :fix_date=>0,
       :sell_or_buy=>:buy,
       :price=>1010800.0,
       :trader=>"a",
       :position_id=>p1.position_id,
       :raw_position_id=>nil,
       :profit_or_loss=>-500.0,
       :swap=>0
    }
    assert_equals @dao.list_positions("30s"), {
      p1.position_id=> p1_props
    }
    assert_equals read_profit_or_loss("30s"), [
      ["0", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,30).to_i.to_s],
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,30).to_i.to_s, Time.local(2008,8,7,0,0,60).to_i.to_s]
    ]
    assert_equals @dao.list_positions("1m"), {
      p1.position_id=> p1_props
    }
    assert_equals read_profit_or_loss("1m"), [
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,60).to_i.to_s]
    ]

    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,0,30)), {}
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,0,30)), {}
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,2)), {
      p1.position_id=> p1_props
    }
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,2)), {
      p1.position_id=> p1_props
    }

    # 注文
    p2 = op.sell( 1, :USDJPY, "b" )
    p2_props = p2.values
    op.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.0, 100.05, -250, 250 ),
      :AUDUSD => JIJI::Rate.new( 100.0, 100.05, -250, 250 )
    }, Time.local(2008,8,7,0,1,21)  ))

    # プロパティは購入/売却/コミット時にのみ更新される。
    assert_equals @dao.list_positions("30s"), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals read_profit_or_loss("30s"), [
      ["0", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,30).to_i.to_s],
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,30).to_i.to_s, Time.local(2008,8,7,0,0,60).to_i.to_s]
    ]
    assert_equals @dao.list_positions("1m"), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals read_profit_or_loss("1m"), [
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,60).to_i.to_s]
    ]

    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,0,30)), {}
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,0,30)), {}
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,0)), {
      p1.position_id=> p1_props
    }
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,0)), {
      p1.position_id=> p1_props
    }
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,1,10), Time.local(2008,8,7,0,1,30)), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,1,10), Time.local(2008,8,7,0,1,30)), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,30)), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,30)), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    
    # 次のレート
    # 取引データ、損益データが記録される
    op.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.1, 100.15, -250, 250 ),
      :AUDUSD => JIJI::Rate.new( 100.1, 100.15, -250, 250 )
    }, Time.local(2008,8,7,0,1,33)  ))

    assert_equals @dao.list_positions("30s"), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals read_profit_or_loss("30s"), [
      ["0", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,30).to_i.to_s],
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,30).to_i.to_s, Time.local(2008,8,7,0,0,60).to_i.to_s],
      ["-1300", "0", "0.0", Time.local(2008,8,7,0,1,0).to_i.to_s, Time.local(2008,8,7,0,1,30).to_i.to_s]
    ]
    assert_equals @dao.list_positions("1m"), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals read_profit_or_loss("1m"), [
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,60).to_i.to_s]
    ]

    # 約定
    op.commit(p1)
    p1_props = p1.values
    assert_equals @dao.list_positions("30s"), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals read_profit_or_loss("30s"), [
      ["0", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,30).to_i.to_s],
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,30).to_i.to_s, Time.local(2008,8,7,0,0,60).to_i.to_s],
      ["-1300", "0", "0.0", Time.local(2008,8,7,0,1,0).to_i.to_s, Time.local(2008,8,7,0,1,30).to_i.to_s]
    ]
    assert_equals @dao.list_positions("1m"), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals read_profit_or_loss("1m"), [
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,60).to_i.to_s]
    ]
    
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,0,30)), {}
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,0,30)), {}
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,0)), {
      p1.position_id=> p1_props
    }
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,0)), {
      p1.position_id=> p1_props
    }
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,1,10), Time.local(2008,8,7,0,1,30)), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,1,10), Time.local(2008,8,7,0,1,30)), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,30)), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,30)), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    
    # 次のレート
    # 取引データ、損益データが記録される
    op.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 101.0, 101.05, -250, 250 ),
      :AUDUSD => JIJI::Rate.new( 101.0, 101.05, -250, 250 )
    }, Time.local(2008,8,7,0,2,0)  ))
    assert_equals @dao.list_positions("30s"), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals read_profit_or_loss("30s"), [
      ["0", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,30).to_i.to_s],
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,30).to_i.to_s, Time.local(2008,8,7,0,0,60).to_i.to_s],
      ["-1300", "0", "0.0", Time.local(2008,8,7,0,1,0).to_i.to_s, Time.local(2008,8,7,0,1,30).to_i.to_s],
      ["-10300", "-9800", "0.0", Time.local(2008,8,7,0,1,30).to_i.to_s, Time.local(2008,8,7,0,2,0).to_i.to_s]
    ]
    assert_equals @dao.list_positions("1m"), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals read_profit_or_loss("1m"), [
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,1,0).to_i.to_s],
      ["-10300", "-9800", "0.0", Time.local(2008,8,7,0,1,0).to_i.to_s, Time.local(2008,8,7,0,2,0).to_i.to_s]
    ]

    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,0,30)), {}
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,0,30)), {}
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,0)), {
      p1.position_id=> p1_props
    }
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,0)), {
      p1.position_id=> p1_props
    }
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,1,10), Time.local(2008,8,7,0,1,30)), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,1,10), Time.local(2008,8,7,0,2,0)), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,30)), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,2,0)), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,1,35), Time.local(2008,8,7,0,2,0)), {
      p2.position_id=> p2_props
    }
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,1,35), Time.local(2008,8,7,0,2,0)), {
      p2.position_id=> p2_props
    }

    # 次
    op.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.5, 100.55, -250, 250 ),
      :AUDUSD => JIJI::Rate.new( 100.5, 100.55, -250, 250 )
    }, Time.local(2008,8,7,0,2,31)  ))
    assert_equals @dao.list_positions("30s"), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals read_profit_or_loss("30s"), [
      ["0", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,30).to_i.to_s],
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,30).to_i.to_s, Time.local(2008,8,7,0,0,60).to_i.to_s],
      ["-1300", "0", "0.0", Time.local(2008,8,7,0,1,0).to_i.to_s, Time.local(2008,8,7,0,1,30).to_i.to_s],
      ["-10300", "-9800", "0.0", Time.local(2008,8,7,0,1,30).to_i.to_s, Time.local(2008,8,7,0,2,0).to_i.to_s],
      ["-5300", "-9800", "0.0", Time.local(2008,8,7,0,2,0).to_i.to_s, Time.local(2008,8,7,0,2,30).to_i.to_s]
    ]
    assert_equals @dao.list_positions("1m"), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals read_profit_or_loss("1m"), [
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,1,0).to_i.to_s],
      ["-10300", "-9800", "0.0", Time.local(2008,8,7,0,1,0).to_i.to_s, Time.local(2008,8,7,0,2,0).to_i.to_s]
    ]

    # p2をコミット
    op.commit(p2)
    p2_props = p2.values
    op.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 100.5, 100.55, -250, 250 ),
      :AUDUSD => JIJI::Rate.new( 100.5, 100.55, -250, 250 )
    }, Time.local(2008,8,7,0,3,0)  ))
    assert_equals @dao.list_positions("30s"), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals read_profit_or_loss("30s"), [
      ["0", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,30).to_i.to_s],
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,30).to_i.to_s, Time.local(2008,8,7,0,0,60).to_i.to_s],
      ["-1300", "0", "0.0", Time.local(2008,8,7,0,1,0).to_i.to_s, Time.local(2008,8,7,0,1,30).to_i.to_s],
      ["-10300", "-9800", "0.0", Time.local(2008,8,7,0,1,30).to_i.to_s, Time.local(2008,8,7,0,2,0).to_i.to_s],
      ["-5300", "-9800", "0.0", Time.local(2008,8,7,0,2,0).to_i.to_s, Time.local(2008,8,7,0,2,30).to_i.to_s],
      ["-5300", "-5300", "0.5", Time.local(2008,8,7,0,2,30).to_i.to_s, Time.local(2008,8,7,0,3,0).to_i.to_s]
    ]
    assert_equals @dao.list_positions("1m"), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals read_profit_or_loss("1m"), [
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,1,0).to_i.to_s],
      ["-10300", "-9800", "0.0", Time.local(2008,8,7,0,1,0).to_i.to_s, Time.local(2008,8,7,0,2,0).to_i.to_s],
      ["-5300", "-5300", "0.5", Time.local(2008,8,7,0,2,0).to_i.to_s, Time.local(2008,8,7,0,3,0).to_i.to_s]
    ]

    # 次
    op.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 101.5, 101.55, -250, 250 ),
      :AUDUSD => JIJI::Rate.new( 101.5, 101.55, -250, 250 )
    }, Time.local(2008,8,7,0,3,31)  ))
    assert_equals @dao.list_positions("30s"), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals read_profit_or_loss("30s"), [
      ["0", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,30).to_i.to_s],
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,30).to_i.to_s, Time.local(2008,8,7,0,0,60).to_i.to_s],
      ["-1300", "0", "0.0", Time.local(2008,8,7,0,1,0).to_i.to_s, Time.local(2008,8,7,0,1,30).to_i.to_s],
      ["-10300", "-9800", "0.0", Time.local(2008,8,7,0,1,30).to_i.to_s, Time.local(2008,8,7,0,2,0).to_i.to_s],
      ["-5300", "-9800", "0.0", Time.local(2008,8,7,0,2,0).to_i.to_s, Time.local(2008,8,7,0,2,30).to_i.to_s],
      ["-5300", "-5300", "0.5", Time.local(2008,8,7,0,2,30).to_i.to_s, Time.local(2008,8,7,0,3,0).to_i.to_s],
      ["-5300", "-5300", "0.5", Time.local(2008,8,7,0,3,0).to_i.to_s, Time.local(2008,8,7,0,3,30).to_i.to_s]
    ]
    assert_equals @dao.list_positions("1m"), {
      p1.position_id=> p1_props,
      p2.position_id=> p2_props
    }
    assert_equals read_profit_or_loss("1m"), [
      ["-800", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,1,0).to_i.to_s],
      ["-10300", "-9800", "0.0", Time.local(2008,8,7,0,1,0).to_i.to_s, Time.local(2008,8,7,0,2,0).to_i.to_s],
      ["-5300", "-5300", "0.5", Time.local(2008,8,7,0,2,0).to_i.to_s, Time.local(2008,8,7,0,3,0).to_i.to_s]
    ]

    # コミット済みデータは削除される
    assert_equals op.positions.length, 0

    # 部分取得
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,0,50)), {}
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,0)), {
      p1.position_id=> p1_props
    }
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,2,0), Time.local(2008,8,7,0,2,30)), {
      p2.position_id=> p2_props,
    }
    assert_equals @dao.list_positions("30s", Time.local(2008,8,7,0,3,0), Time.local(2008,8,7,0,3,30)), {}

    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,0,50)), {}
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,0,0), Time.local(2008,8,7,0,1,0)), {
      p1.position_id=> p1_props,
    }
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,2,1), Time.local(2008,8,7,0,3,0)), {
      p2.position_id=> p2_props,
    }
    assert_equals @dao.list_positions("1m", Time.local(2008,8,7,0,3,1), Time.local(2008,8,7,0,7,0)), {}

  end

  # flush のテスト。
  def test_flush()
    pair_infos = {
      :USDJPY => Info.new( 10000 ),
      :AUDUSD => Info.new( 10000 )
    }

    op = JIJI::Operator.new @dao
    op.conf = CONF
    op.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 101.0, 101.05, -250, 250 ),
      :AUDUSD => JIJI::Rate.new( 101.0, 101.05, -250, 250 )
    }, Time.local(2008,8,7,0,0,0)))

    assert_equals @dao.list_positions("30s"), {}
    assert_equals @dao.list_positions("1m"), {}
    assert_equals @dao.list_positions("5m"), {}

    op.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 101.03, 101.08, -250, 250 ),
      :AUDUSD => JIJI::Rate.new( 101.03, 101.08, -250, 250 )
    }, Time.local(2008,8,7,0,0,40)))

    assert_equals @dao.list_positions("30s"), {}
    assert_equals read_profit_or_loss("30s"), [
      ["0", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,30).to_i.to_s]
    ]
    assert_equals @dao.list_positions("1m"), {}
    assert_equals read_profit_or_loss("1m"), []
    assert_equals @dao.list_positions("5m"), {}
    assert_equals read_profit_or_loss("5m"), []

    # 注文
    p1 = op.buy( 1, :USDJPY, "a" )
    op.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => JIJI::Rate.new( 101.0, 101.05, -250, 250 ),
      :AUDUSD => JIJI::Rate.new( 101.0, 101.05, -250, 250 )
    }, Time.local(2008,8,7,0,0,50)  ))

    # 1mは経過していないので、バッファ内のデータは保存されていない。
    p1_props = {
       :count=>1,
       :rate=>101.08,
       :state=>1,
       :fix_rate=>nil,
       :date=>1218034840,
       :pair=>:USDJPY,
       :fix_date=>0,
       :sell_or_buy=>:buy,
       :price=>1010800.0,
       :trader=>"a",
       :position_id=>p1.position_id,
       :raw_position_id=>nil,
       :profit_or_loss=>-500.0,
       :swap=>0
    }
    assert_equals @dao.list_positions("30s"), {
      p1.position_id=> p1_props
    }
    assert_equals read_profit_or_loss("30s"), [
      ["0", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,30).to_i.to_s]
    ]
    assert_equals @dao.list_positions("1m"), {
      p1.position_id=> p1_props
    }
    assert_equals read_profit_or_loss("1m"), []
    assert_equals @dao.list_positions("5m"), {
      p1.position_id=> p1_props
    }
    assert_equals read_profit_or_loss("5m"), []

    # 強制書き出し
    # ポジションデータのみ強制的に書き出される。
    @dao.flush( Time.local(2008,8,7,0,0,55) )
    assert_equals @dao.list_positions("30s"), {
      p1.position_id=> p1_props
    }
    assert_equals read_profit_or_loss("30s"), [
      ["0", "0", "0.0", Time.local(2008,8,7,0,0,0).to_i.to_s, Time.local(2008,8,7,0,0,30).to_i.to_s]
    ]
    assert_equals @dao.list_positions("1m"), {
      p1.position_id=> p1_props # データが書き出される
    }
    assert_equals read_profit_or_loss("1m"), []
    assert_equals @dao.list_positions("5m"), {
      p1.position_id=> p1_props # データが書き出される
    }
    assert_equals read_profit_or_loss("5m"), []
  end


  def read_profit_or_loss( scale, start_date=nil, end_date=nil )
    list = []
    @dao.each( scale, start_date, end_date ) {|row| list << row }
    return list
  end

end