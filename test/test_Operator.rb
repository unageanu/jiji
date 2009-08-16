#!/usr/bin/ruby

$: << "../lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/operator'
require 'jiji/collector'
require 'jiji/agent/agent'
require 'jiji/agent/agent_manager'
require 'jiji/agent/agent_registry'
require 'jiji/agent/permitter'
require 'jiji/agent/util'
require 'test_utils'

class OperatorTest <  RUNIT::TestCase

  include Test::Constants

  def setup
    @operator = JIJI::Operator.new nil, 200000
    @operator.conf = CONF
  end

  def teardown
  end

  def test_basic

    pair_infos = {
      :EURJPY => Info.new( 10000 )
    }

    # 初期状態は建玉,損益共に0
    assert_equals  @operator.profit_or_loss, 0
    assert_equals  @operator.positions, {}

    # レートを挿入
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.0,100.05,-200,200,1 )
    })
    time_1 = rates.time
    @operator.next_rates( rates )
    assert_equals  @operator.profit_or_loss, 0
    assert_equals  @operator.positions, {}

    # 購入
    sell_1 = @operator.sell 1
    assert_equals sell_1.sell_or_buy, JIJI::Position::SELL
    assert_equals sell_1.state, JIJI::Position::STATE_START
    assert_equals sell_1.date, time_1
    assert_equals sell_1.fix_date, nil
    assert_equals sell_1.count, 1
    assert_equals sell_1.price, 1000000
    assert_equals sell_1.current_price, 1000500
    assert_equals sell_1.profit_or_loss, -500

    buy_1 = @operator.buy 1
    assert_equals buy_1.sell_or_buy, JIJI::Position::BUY
    assert_equals buy_1.state, JIJI::Position::STATE_START
    assert_equals buy_1.date, time_1
    assert_equals buy_1.fix_date, nil
    assert_equals buy_1.count, 1
    assert_equals buy_1.price, 1000500
    assert_equals buy_1.current_price, 1000000
    assert_equals buy_1.profit_or_loss, -500

    assert_equals  @operator.profit_or_loss, -1000
    assert_equals  @operator.fixed_profit_or_loss, 0
    assert_equals  @operator.positions.length, 2
    assert_equals  @operator.win_rate, 0.0

    # レートを更新
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.05,100.10,-200,200,2 )
    })
    @operator.next_rates( rates )

    assert_equals sell_1.sell_or_buy, JIJI::Position::SELL
    assert_equals sell_1.state, JIJI::Position::STATE_START
    assert_equals sell_1.date, time_1
    assert_equals sell_1.fix_date, nil
    assert_equals sell_1.count, 1
    assert_equals sell_1.price, 1000000
    assert_equals sell_1.current_price, 1001000
    assert_equals sell_1.profit_or_loss, -1000

    assert_equals buy_1.sell_or_buy, JIJI::Position::BUY
    assert_equals buy_1.state, JIJI::Position::STATE_START
    assert_equals buy_1.date, time_1
    assert_equals buy_1.fix_date, nil
    assert_equals buy_1.count, 1
    assert_equals buy_1.price, 1000500
    assert_equals buy_1.current_price, 1000500
    assert_equals buy_1.profit_or_loss, 0

    assert_equals  @operator.profit_or_loss, -1000
    assert_equals  @operator.fixed_profit_or_loss, 0
    assert_equals  @operator.positions.length, 2
    assert_equals  @operator.win_rate, 0.0

    # レートを更新
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.20,100.25,-200,200,3 )
    })
    time_3 = rates.time
    @operator.next_rates( rates )

    assert_equals sell_1.sell_or_buy, JIJI::Position::SELL
    assert_equals sell_1.state, JIJI::Position::STATE_START
    assert_equals sell_1.date, time_1
    assert_equals sell_1.fix_date, nil
    assert_equals sell_1.count, 1
    assert_equals sell_1.price, 1000000
    assert_equals sell_1.current_price, 1002500
    assert_equals sell_1.profit_or_loss, -2500

    assert_equals buy_1.sell_or_buy, JIJI::Position::BUY
    assert_equals buy_1.state, JIJI::Position::STATE_START
    assert_equals buy_1.date, time_1
    assert_equals buy_1.fix_date, nil
    assert_equals buy_1.count, 1
    assert_equals buy_1.price, 1000500
    assert_equals buy_1.current_price, 1002000
    assert_equals buy_1.profit_or_loss, 1500

    assert_equals  @operator.profit_or_loss, -1000
    assert_equals  @operator.fixed_profit_or_loss, 0
    assert_equals  @operator.positions.length, 2
    assert_equals  @operator.win_rate, 0.0


    # sell をコミット
    @operator.commit(sell_1)
    assert_equals sell_1.sell_or_buy, JIJI::Position::SELL
    assert_equals sell_1.state, JIJI::Position::STATE_FIXED
    assert_equals sell_1.date, time_1
    assert_equals sell_1.fix_date, time_3
    assert_equals sell_1.count, 1
    assert_equals sell_1.price, 1000000
    assert_equals sell_1.current_price, 1002500
    assert_equals sell_1.profit_or_loss, -2500


    # レートを更新
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.15,100.20,-200,200,4 )
    })
    time_4 = rates.time
    @operator.next_rates( rates )

    assert_equals sell_1.sell_or_buy, JIJI::Position::SELL
    assert_equals sell_1.state, JIJI::Position::STATE_FIXED
    assert_equals sell_1.date, time_1
    assert_equals sell_1.fix_date, time_3
    assert_equals sell_1.count, 1
    assert_equals sell_1.price, 1000000
    assert_equals sell_1.current_price, 1002500
    assert_equals sell_1.profit_or_loss, -2500

    assert_equals buy_1.sell_or_buy, JIJI::Position::BUY
    assert_equals buy_1.state, JIJI::Position::STATE_START
    assert_equals buy_1.date, time_1
    assert_equals buy_1.fix_date, nil
    assert_equals buy_1.count, 1
    assert_equals buy_1.price, 1000500
    assert_equals buy_1.current_price, 1001500
    assert_equals buy_1.profit_or_loss, 1000

    assert_equals  @operator.profit_or_loss, -1500
    assert_equals  @operator.fixed_profit_or_loss, -2500
    assert_equals  @operator.positions.length, 1
    assert_equals  @operator.win_rate, 0.0

    # 新規買い
    buy_2 = @operator.buy 2
    assert_equals buy_2.sell_or_buy, JIJI::Position::BUY
    assert_equals buy_2.state, JIJI::Position::STATE_START
    assert_equals buy_2.date, time_4
    assert_equals buy_2.fix_date, nil
    assert_equals buy_2.count, 2
    assert_equals buy_2.price, 2004000
    assert_equals buy_2.current_price, 2003000
    assert_equals buy_2.profit_or_loss, -1000

    assert_equals  @operator.profit_or_loss, -2500
    assert_equals  @operator.fixed_profit_or_loss, -2500
    assert_equals  @operator.positions.length, 2
    assert_equals  @operator.win_rate, 0.0


    # レートを更新
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.20,100.25,-200,200,5 )
    })
    time_5 = rates.time
    @operator.next_rates( rates )

    assert_equals sell_1.sell_or_buy, JIJI::Position::SELL
    assert_equals sell_1.state, JIJI::Position::STATE_FIXED
    assert_equals sell_1.date, time_1
    assert_equals sell_1.fix_date, time_3
    assert_equals sell_1.count, 1
    assert_equals sell_1.price, 1000000
    assert_equals sell_1.current_price, 1002500
    assert_equals sell_1.profit_or_loss, -2500

    assert_equals buy_1.sell_or_buy, JIJI::Position::BUY
    assert_equals buy_1.state, JIJI::Position::STATE_START
    assert_equals buy_1.date, time_1
    assert_equals buy_1.fix_date, nil
    assert_equals buy_1.count, 1
    assert_equals buy_1.price, 1000500
    assert_equals buy_1.current_price, 1002000
    assert_equals buy_1.profit_or_loss, 1500

    assert_equals buy_2.sell_or_buy, JIJI::Position::BUY
    assert_equals buy_2.state, JIJI::Position::STATE_START
    assert_equals buy_2.date, time_4
    assert_equals buy_2.fix_date, nil
    assert_equals buy_2.count, 2
    assert_equals buy_2.price, 2004000
    assert_equals buy_2.current_price, 2004000
    assert_equals buy_2.profit_or_loss, 0

    assert_equals  @operator.profit_or_loss, -1000
    assert_equals  @operator.fixed_profit_or_loss, -2500
    assert_equals  @operator.positions.length, 2
    assert_equals  @operator.win_rate, 0.0


    @operator.commit(buy_1)
    @operator.commit(buy_2)

    assert_equals sell_1.sell_or_buy, JIJI::Position::SELL
    assert_equals sell_1.state, JIJI::Position::STATE_FIXED
    assert_equals sell_1.date, time_1
    assert_equals sell_1.fix_date, time_3
    assert_equals sell_1.count, 1
    assert_equals sell_1.price, 1000000
    assert_equals sell_1.current_price, 1002500
    assert_equals sell_1.profit_or_loss, -2500

    assert_equals buy_1.sell_or_buy, JIJI::Position::BUY
    assert_equals buy_1.state, JIJI::Position::STATE_FIXED
    assert_equals buy_1.date, time_1
    assert_equals buy_1.fix_date, time_5
    assert_equals buy_1.count, 1
    assert_equals buy_1.price, 1000500
    assert_equals buy_1.current_price, 1002000
    assert_equals buy_1.profit_or_loss, 1500

    assert_equals buy_2.sell_or_buy, JIJI::Position::BUY
    assert_equals buy_2.state, JIJI::Position::STATE_FIXED
    assert_equals buy_2.date, time_4
    assert_equals buy_2.fix_date, time_5
    assert_equals buy_2.count, 2
    assert_equals buy_2.price, 2004000
    assert_equals buy_2.current_price, 2004000
    assert_equals buy_2.profit_or_loss, 0

    assert_equals  @operator.profit_or_loss, -1000
    assert_equals  @operator.fixed_profit_or_loss, -1000
    assert_equals  @operator.positions.length, 0
    assert_equals  @operator.win_rate, 1.0/3

    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.30,100.35,-200,200,6 )
    })
    @operator.next_rates( rates )

    assert_equals sell_1.sell_or_buy, JIJI::Position::SELL
    assert_equals sell_1.state, JIJI::Position::STATE_FIXED
    assert_equals sell_1.date, time_1
    assert_equals sell_1.fix_date, time_3
    assert_equals sell_1.count, 1
    assert_equals sell_1.price, 1000000
    assert_equals sell_1.current_price, 1002500
    assert_equals sell_1.profit_or_loss, -2500

    assert_equals buy_1.sell_or_buy, JIJI::Position::BUY
    assert_equals buy_1.state, JIJI::Position::STATE_FIXED
    assert_equals buy_1.date, time_1
    assert_equals buy_1.fix_date, time_5
    assert_equals buy_1.count, 1
    assert_equals buy_1.price, 1000500
    assert_equals buy_1.current_price, 1002000
    assert_equals buy_1.profit_or_loss, 1500

    assert_equals buy_2.sell_or_buy, JIJI::Position::BUY
    assert_equals buy_2.state, JIJI::Position::STATE_FIXED
    assert_equals buy_2.date, time_4
    assert_equals buy_2.fix_date, time_5
    assert_equals buy_2.count, 2
    assert_equals buy_2.price, 2004000
    assert_equals buy_2.current_price, 2004000
    assert_equals buy_2.profit_or_loss, 0

    assert_equals  @operator.profit_or_loss, -1000
    assert_equals  @operator.fixed_profit_or_loss, -1000
    assert_equals  @operator.positions.length, 0
    assert_equals  @operator.win_rate, 1.0/3

  end

  # stopのテスト。
  def test_stop

    pair_infos = {
      :EURJPY => Info.new( 10000 )
    }

    # レートを挿入
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.0,100.05,-200,200,1 )
    })
    time_1 = rates.time
    @operator.next_rates( rates )
    assert_equals  @operator.profit_or_loss, 0
    assert_equals  @operator.positions, {}

    # 購入
    sell_1 = @operator.sell 1
    buy_1 = @operator.buy 1


    # レートを更新
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.05,100.10,-200,200,2 )
    })
    @operator.next_rates( rates )

    assert_equals sell_1.sell_or_buy, JIJI::Position::SELL
    assert_equals sell_1.state, JIJI::Position::STATE_START
    assert_equals sell_1.date, time_1
    assert_equals sell_1.fix_date, nil
    assert_equals sell_1.count, 1
    assert_equals sell_1.price, 1000000
    assert_equals sell_1.current_price, 1001000
    assert_equals sell_1.profit_or_loss, -1000

    assert_equals buy_1.sell_or_buy, JIJI::Position::BUY
    assert_equals buy_1.state, JIJI::Position::STATE_START
    assert_equals buy_1.date, time_1
    assert_equals buy_1.fix_date, nil
    assert_equals buy_1.count, 1
    assert_equals buy_1.price, 1000500
    assert_equals buy_1.current_price, 1000500
    assert_equals buy_1.profit_or_loss, 0

    @operator.stop
    assert_equals sell_1.sell_or_buy, JIJI::Position::SELL
    assert_equals sell_1.state, JIJI::Position::STATE_LOST
    assert_equals sell_1.date, time_1
    assert_equals sell_1.fix_date, nil
    assert_equals sell_1.count, 1
    assert_equals sell_1.price, 1000000
    assert_equals sell_1.current_price, 1001000
    assert_equals sell_1.profit_or_loss, -1000

    assert_equals buy_1.sell_or_buy, JIJI::Position::BUY
    assert_equals buy_1.state, JIJI::Position::STATE_LOST
    assert_equals buy_1.date, time_1
    assert_equals buy_1.fix_date, nil
    assert_equals buy_1.count, 1
    assert_equals buy_1.price, 1000500
    assert_equals buy_1.current_price, 1000500
    assert_equals buy_1.profit_or_loss, 0

  end

  # スワップのテスト
  def test_swap

    pair_infos = {
      :EURJPY => Info.new( 10000 )
    }

    # レートを挿入
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.05,100.10,-200,200, Time.local( 2000, 1, 1, 0, 0, 0 ) )
    }, Time.local( 2000, 1, 1, 0, 0, 0 ))
    @operator.next_rates( rates )

    # 取引
    sell_1 = @operator.sell 1
    assert_equals sell_1.sell_or_buy, JIJI::Position::SELL
    assert_equals sell_1.price, 1000500
    assert_equals sell_1.current_price, 1001000
    assert_equals sell_1.profit_or_loss, -500
    assert_equals sell_1.swap, 0

    buy_1 = @operator.buy 1
    assert_equals buy_1.sell_or_buy, JIJI::Position::BUY
    assert_equals buy_1.price, 1001000
    assert_equals buy_1.current_price, 1000500
    assert_equals buy_1.profit_or_loss, -500
    assert_equals buy_1.swap, 0


    # レートを更新
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.05,100.10,-200,200,Time.local( 2000, 1, 1, 3, 59, 59 ) )
    }, Time.local( 2000, 1, 1, 3, 59, 59 ))
    @operator.next_rates( rates )

    # 時間前なので、スワップは更新されない
    assert_equals sell_1.swap, 0
    assert_equals buy_1.swap, 0

    # レートを更新
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.05,100.10,-200,200,Time.local( 2000, 1, 1, 5, 0, 0 ) )
    },Time.local( 2000, 1, 1, 5, 0, 0 ))
    @operator.next_rates( rates )

    # スワップが+される
    assert_equals sell_1.swap, -200
    assert_equals buy_1.swap, 200


    # レートを更新
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.05,100.10,-200,200,Time.local( 2000, 1, 1, 5, 0, 0 ) )
    },Time.local( 2000, 1, 1, 5, 0, 0 ))
    @operator.next_rates( rates )

    # スワップはそのまま
    assert_equals sell_1.swap, -200
    assert_equals sell_1.current_price, 1001000
    assert_equals sell_1.profit_or_loss, -700
    assert_equals buy_1.swap, 200
    assert_equals buy_1.current_price, 1000500
    assert_equals buy_1.profit_or_loss, -300

    # レートを更新
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.05,100.10,-200,200,Time.local( 2000, 1, 1, 5, 10, 0 ) )
    },Time.local( 2000, 1, 1, 5, 10, 0 ))
    @operator.next_rates( rates )

    # スワップはそのまま
    assert_equals sell_1.swap, -200
    assert_equals sell_1.current_price, 1001000
    assert_equals sell_1.profit_or_loss, -700
    assert_equals buy_1.swap, 200
    assert_equals buy_1.current_price, 1000500
    assert_equals buy_1.profit_or_loss, -300


    # さらに取引
    sell_2 = @operator.sell 1
    assert_equals sell_2.sell_or_buy, JIJI::Position::SELL
    assert_equals sell_2.price, 1000500
    assert_equals sell_2.current_price, 1001000
    assert_equals sell_2.profit_or_loss, -500
    assert_equals sell_2.swap, 0


    # レートを更新
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.05,100.10,-200,200,Time.local( 2000, 1, 1, 12, 0, 0 ) )
    },Time.local( 2000, 1, 1, 12, 0, 0 ))
    @operator.next_rates( rates )
    # スワップはそのまま
    assert_equals sell_1.swap, -200
    assert_equals buy_1.swap, 200
    assert_equals sell_2.swap, 0


    # レートを更新
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.05,100.10,-200,200,Time.local( 2000, 1, 2, 3, 0, 0 ) )
    },Time.local( 2000, 1, 2, 3, 0, 0 ))
    @operator.next_rates( rates )
    # スワップはそのまま
    assert_equals sell_1.swap, -200
    assert_equals buy_1.swap, 200
    assert_equals sell_2.swap, 0

    # レートを更新
    rates = JIJI::Rates.new( pair_infos, {
      :EURJPY => Rate.new( 100.05,100.10,-100,100,Time.local( 2000, 1, 2, 5, 0, 10 ) )
    },Time.local( 2000, 1, 2, 5, 0, 10 ))
    @operator.next_rates( rates )
    # スワップも更新される
    assert_equals sell_1.swap, -300
    assert_equals sell_1.current_price, 1001000
    assert_equals sell_1.profit_or_loss, -800
    assert_equals buy_1.swap, 300
    assert_equals buy_1.current_price, 1000500
    assert_equals buy_1.profit_or_loss, -200
    assert_equals sell_2.swap, -100
    assert_equals sell_2.current_price, 1001000
    assert_equals sell_2.profit_or_loss, -600

  end


end
