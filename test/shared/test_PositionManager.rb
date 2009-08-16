#!/usr/bin/ruby

$: << "../lib"
$: << "../base/shared_lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'system/position_manager'
require 'set'
require 'jiji/operator'

class PositionManagerTest <  RUNIT::TestCase

  # 前準備
  def setup
    @op = MockOperator.new
    @pm = PositionManager.new(@op)
  end

  # 後始末
  def teardown
  end


  # 基本動作のテスト
  def test_commit

    assert_equals( @pm.total_profit_or_loss, 0)

    #each
    assert_equals( @pm.map.size, 0)

    #commit
    @pm.commit_by {|p| true }
    assert_equals(@op.commited.size, 0)
    @op.commited.clear
    @pm.commit_all
    assert_equals(@op.commited.size, 0)

    #ポジションを追加
    ps = [
      Position.new( 1, 100, JIJI::Position::STATE_START ),
      Position.new( 2, 200, JIJI::Position::STATE_START ),
      Position.new( 3, 300, JIJI::Position::STATE_START ),
      Position.new( 4, 400, JIJI::Position::STATE_START )
    ]
    ps.each{|p| @op << p }

    assert_equals( @pm.total_profit_or_loss, 1000)

    # each
    assert_equals( @pm.map.size, 4)

    @pm.commit_by {|p| p.position_id == 1 }
    assert_equals(@op.commited.size, 1)
    @pm.commit_all
    assert_equals(@op.commited.size, 4)
  end

  # strategyの追加、削除のテスト
  def test_strategy
    #ポジションを追加
    p = Position.new( 1, 0, JIJI::Position::STATE_START )
    @op << p

    assert( !@pm.registered?(p.position_id) )
    assert_equals( @pm.get_registered_strategy(p.position_id).size, 0 )

    #損切り対象としてマーク
    @pm.register_loss_cut( p.position_id, -1000 )
    @pm.register_trailing_stop( p.position_id, -1000 )
    @pm.register( p.position_id, Object.new )

    registerd = @pm.get_registered_strategy(p.position_id)
    assert( @pm.registered?(p.position_id) )
    assert_equals( registerd.size, 3 )

    #削除
    @pm.unregister( p.position_id, registerd[1] )
    assert( @pm.registered?(p.position_id) )
    assert_equals( @pm.get_registered_strategy(p.position_id).size, 2 )

    @pm.unregister_all( p.position_id )
    assert( !@pm.registered?(p.position_id) )
    assert_equals( @pm.get_registered_strategy(p.position_id).size, 0 )

  end

  # losscutのテスト
  def test_losscut

    #ポジションを追加
    ps = [
      Position.new( 1, 0, JIJI::Position::STATE_START ),
      Position.new( 2, 0, JIJI::Position::STATE_START ),
      Position.new( 3, 0, JIJI::Position::STATE_START ),
      Position.new( 4, 0, JIJI::Position::STATE_START )
    ]
    ps.each{|p| @op << p }

    #損切り対象としてマーク
    @pm.register_loss_cut( ps[0].position_id, -1000 )
    @pm.register_loss_cut( ps[1].position_id, -1000 )
    @pm.register_loss_cut( ps[2].position_id, -1500 )
    @pm.register_loss_cut( ps[3].position_id, -2000 )
    ps.each {|p|
      assert( @pm.registered?(p.position_id) )
      assert_equals( @pm.get_registered_strategy(p.position_id).size, 1 )
    }

    # 初回のチェック。何もコミットされない
    assert_equals( @pm.check, [] )

    # ポジションの損失を-1100に設定
    ps.each {|p| p.profit_or_loss = -1100 }
    assert_equals( @pm.check, ps[0..1] ) # 1～2が決済される
    assert( @op.commited.include?( 1 ) )
    assert( @op.commited.include?( 2 ) )

    assert( !@pm.registered?(ps[0].position_id) )
    assert_equals( @pm.get_registered_strategy(ps[0].position_id).size, 0 )
    assert( !@pm.registered?(ps[1].position_id) )
    assert_equals( @pm.get_registered_strategy(ps[1].position_id).size, 0 )

    # ポジションの損失を-1500に設定
    ps.each {|p| p.profit_or_loss = -1500 }
    assert_equals( @pm.check, [ps[2]] ) # 3が決済される
    assert( @op.commited.include?( 1 ) )
    assert( @op.commited.include?( 2 ) )
    assert( @op.commited.include?( 3 ) )

    assert( !@pm.registered?(ps[2].position_id) )
    assert_equals( @pm.get_registered_strategy(ps[2].position_id).size, 0 )

  end

  # trailing_stopのテスト
  def test_trailing_stop

    #ポジションを追加
    ps = [
      Position.new( 1, 0, JIJI::Position::STATE_START ),
      Position.new( 2, 0, JIJI::Position::STATE_START ),
      Position.new( 3, 0, JIJI::Position::STATE_START ),
      Position.new( 4, 0, JIJI::Position::STATE_START )
    ]
    ps.each{|p| @op << p }

    #トレーリングストップの対象としてマーク
    @pm.register_trailing_stop( ps[0].position_id, -1000 )
    @pm.register_trailing_stop( ps[1].position_id, -1000 )
    @pm.register_trailing_stop( ps[2].position_id, -1500 )
    @pm.register_trailing_stop( ps[3].position_id, -2000 )
    ps.each {|p|
      assert( @pm.registered?(p.position_id) )
      assert_equals( @pm.get_registered_strategy(p.position_id).size, 1 )
    }

    # 初回のチェック。何もコミットされない
    assert_equals( @pm.check, [] )

    # ポジションの損失を-1100に設定
    ps.each {|p| p.profit_or_loss = -1100 }
    assert_equals( @pm.check, ps[0..1] ) # 1～2が決済される
    assert( @op.commited.include?( 1 ) )
    assert( @op.commited.include?( 2 ) )

    assert( !@pm.registered?(ps[0].position_id) )
    assert_equals( @pm.get_registered_strategy(ps[0].position_id).size, 0 )

    assert( !@pm.registered?(ps[1].position_id) )
    assert_equals( @pm.get_registered_strategy(ps[1].position_id).size, 0 )

    # ポジションの利益を1500に設定
    ps.each {|p| p.profit_or_loss = 1500 }
    assert_equals( @pm.check, [] ) # 決済はされない

    # ポジションの利益を2000に設定
    ps.each {|p| p.profit_or_loss = 2000 }
    assert_equals( @pm.check, [] ) # 決済はされない

    # ポジションの利益を500に設定
    ps.each {|p| p.profit_or_loss = 500 }
    assert_equals( @pm.check, [ps[2]] ) # 最大値から1500下がったので、3が決済される
    assert( @op.commited.include?( 1 ) )
    assert( @op.commited.include?( 2 ) )
    assert( @op.commited.include?( 3 ) )

    assert( !@pm.registered?(ps[2].position_id) )
    assert_equals( @pm.get_registered_strategy(ps[2].position_id).size, 0 )

    # ポジションの利益を2500に設定
    ps.each {|p| p.profit_or_loss = 2500 }
    assert_equals( @pm.check, [] ) # 決済はされない

    # ポジションの利益を500に設定
    ps.each {|p| p.profit_or_loss = 500 }
    assert_equals( @pm.check, [ps[3]] ) # 最大値から1500下がったので、4が決済される
    assert( @op.commited.include?( 1 ) )
    assert( @op.commited.include?( 2 ) )
    assert( @op.commited.include?( 3 ) )
    assert( @op.commited.include?( 4 ) )

    assert( !@pm.registered?(ps[3].position_id) )
    assert_equals( @pm.get_registered_strategy(ps[3].position_id).size, 0 )

  end

  # 損切りロジックが複数登録されている場合のテスト
  def test_multi_stop
    #ポジションを追加
    ps = [
      Position.new( 1, 0, JIJI::Position::STATE_START ),
      Position.new( 2, 0, JIJI::Position::STATE_START )
    ]
    ps.each{|p| @op << p }

    # ロスカット
    @pm.register_loss_cut( ps[0].position_id, -500 )
    @pm.register_loss_cut( ps[1].position_id, -2000 )

    @pm.register_trailing_stop( ps[0].position_id, -1000 )
    @pm.register_trailing_stop( ps[1].position_id, -1000 )
    ps.each {|p|
      assert( @pm.registered?(p.position_id) )
      assert_equals( @pm.get_registered_strategy(p.position_id).size, 2 )
    }

    # 初回のチェック。何もコミットされない
    assert_equals( @pm.check, [] )

    # ポジションの損失を-200に設定
    ps.each {|p| p.profit_or_loss = -200 }
    assert_equals( @pm.check, [] )

    # ポジションの利益を200に設定
    ps.each {|p| p.profit_or_loss = 200 }
    assert_equals( @pm.check, [] )

    # ポジションの損失を-500に設定
    ps.each {|p| p.profit_or_loss = -500 }
    assert_equals( @pm.check, [ps[0]] ) # 1が決済される
    assert( @op.commited.include?( 1 ) )

    assert( !@pm.registered?(ps[0].position_id) )
    assert_equals( @pm.get_registered_strategy(ps[0].position_id).size, 0 )

    # ポジションの利益を1500に設定
    ps.each {|p| p.profit_or_loss = 1500 }
    assert_equals( @pm.check, [] ) # 決済はされない

    # ポジションの利益を2000に設定
    ps.each {|p| p.profit_or_loss = 2000 }
    assert_equals( @pm.check, [] ) # 決済はされない

    # ポジションの利益を500に設定
    ps.each {|p| p.profit_or_loss = 1000 }
    assert_equals( @pm.check, [ps[1]] ) # 最大値から1000下がったので、2が決済される
    assert( @op.commited.include?( 1 ) )

    assert( !@pm.registered?(ps[1].position_id) )
    assert_equals( @pm.get_registered_strategy(ps[1].position_id).size, 0 )
  end

  Position = Struct.new( :position_id, :profit_or_loss, :state )

  # テスト用のダミーoperator
  class MockOperator
    def initialize
      @positions = {}
      @commited = []
    end
    def <<(p)
      @positions[p.position_id] = p
    end
    def commit( position )
      @commited ||= Set.new
      @commited << position.position_id
      @positions.delete position.position_id
    end
    attr :commited, true
    attr :positions, true
  end
end