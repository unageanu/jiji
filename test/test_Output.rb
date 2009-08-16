#!/usr/bin/ruby

$: << "../lib"

require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/output'
require 'fileutils'

class OutputTest <  RUNIT::TestCase

  def setup
    @dir = File.dirname(__FILE__) + "/OutputTest.tmp"
    FileUtils.mkdir_p @dir

    @o = JIJI::Output.new( "agent_id", @dir )
    @o.scales = ["30s","1m","1h"]
    @o.agent_name = "エージェント名"
  end

  def teardown
    FileUtils.rm_rf @dir
  end

  def test_basic

    # 書き込み
    out  = @o.get( "テスト",  :event, { :a=>"aaa", :b=>"bbb" } )
    out2 = @o.get( "テスト2", :graph )

    assert_equals @o.agent_name, "エージェント名"
    assert_equals out.options, { :a=>"aaa", :b=>"bbb", :name=>"テスト", :type=>"event" }
    assert_equals out2.options, { :name=>"テスト2", :type=>"graph" }

    @o.time = Time.local(2008, 8, 1, 10, 0, 0)
    out.put( "type", "データ\nデータ" )
    out2.put 100, 110
    @o.time = Time.local(2008, 8, 1, 12, 10, 20)
    out.put( "type2", "データ2\nデータ" )
    out2.put 200, 220
    @o.time = Time.local(2008, 8, 2, 10, 0, 0)
    out.put( "type3", "データ3" )
    @o.time = Time.local(2008, 8, 3, 10, 0, 0)
    out.put( "type4", "データ4" )
    out2.put 10, 20

    # データの取得
    list = read( out, Time.local(2008), Time.local(2008,8,10) )
    assert_equals list, [
      ["type", "データ\nデータ", Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s],
      ["type2", "データ2\nデータ" , Time.local(2008, 8, 1, 12, 10, 20).to_i.to_s],
      ["type3", "データ3" , Time.local(2008, 8, 2, 10, 0, 0).to_i.to_s],
      ["type4", "データ4", Time.local(2008, 8, 3, 10, 0, 0).to_i.to_s]
    ]
    list = read( out, nil, nil )
    assert_equals list, [
      ["type", "データ\nデータ", Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s],
      ["type2", "データ2\nデータ" , Time.local(2008, 8, 1, 12, 10, 20).to_i.to_s],
      ["type3", "データ3" , Time.local(2008, 8, 2, 10, 0, 0).to_i.to_s],
      ["type4", "データ4", Time.local(2008, 8, 3, 10, 0, 0).to_i.to_s]
    ]
    list = read( out, Time.local(2008, 8, 1, 12, 10, 0), Time.local(2008, 8, 3, 0, 0, 0) )
    assert_equals list, [
      ["type2", "データ2\nデータ" , Time.local(2008, 8, 1, 12, 10, 20).to_i.to_s],
      ["type3", "データ3" , Time.local(2008, 8, 2, 10, 0, 0).to_i.to_s]
    ]
    list = read( out, Time.local(2008, 8, 2, 9, 10, 0), nil )
    assert_equals list, [
      ["type3", "データ3" , Time.local(2008, 8, 2, 10, 0, 0).to_i.to_s],
      ["type4", "データ4", Time.local(2008, 8, 3, 10, 0, 0).to_i.to_s]
    ]
    list = read( out, nil, Time.local(2008, 8, 2, 9, 10, 0) )
    assert_equals list, [
      ["type", "データ\nデータ", Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s],
      ["type2", "データ2\nデータ" , Time.local(2008, 8, 1, 12, 10, 20).to_i.to_s]
    ]
    list = read( out, Time.local(2008, 9, 2, 12, 10, 0), Time.local(2008, 9, 2, 13, 10, 0) )
    assert_equals list, []


    list = read( out2, Time.local(2008), Time.local(2008,8,10) )
    assert_equals list, [
      ["100", "110", Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s],
      ["200", "220", Time.local(2008, 8, 1, 12, 10, 20).to_i.to_s],
      ["10" , "20",  Time.local(2008, 8, 3, 10, 0, 0).to_i.to_s]
    ]
    list = read( out2, nil, nil )
    assert_equals list, [
      ["100", "110", Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s],
      ["200", "220", Time.local(2008, 8, 1, 12, 10, 20).to_i.to_s],
      ["10" , "20",  Time.local(2008, 8, 3, 10, 0, 0).to_i.to_s]
    ]
    list = read( out2, Time.local(2008, 8, 1, 12, 10, 0), Time.local(2008, 8, 3, 0, 0, 0) )
    assert_equals list, [
      ["200", "220", Time.local(2008, 8, 1, 12, 10, 20).to_i.to_s]
    ]
    list = read( out2, Time.local(2008, 8, 2, 9, 10, 0), nil )
    assert_equals list, [
      ["10" , "20", Time.local(2008, 8, 3, 10, 0, 0).to_i.to_s]
    ]
    list = read( out2, nil, Time.local(2008, 8, 2, 9, 10, 0) )
    assert_equals list, [
      ["100", "110",  Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s],
      ["200", "220", Time.local(2008, 8, 1, 12, 10, 20).to_i.to_s]
    ]
    list = read( out2, Time.local(2008, 8, 1, 13, 10, 0), Time.local(2008, 8, 1, 13, 10, 0) )
    assert_equals list, []


    # 出力先一覧
    @o.each {|k, v|
      case k
      when "テスト"
        assert_equals v, out
      when "テスト2"
        assert_equals v, out2
      else
        fail
      end
    }

    # 出力先を再取得 # 同じインスタンスが返される
    assert_equals out.object_id,  @o.get( "テスト",  :event ).object_id
    assert_equals out2.object_id, @o.get( "テスト2",  :event ).object_id

    #プロパティの更新
    assert_equals out.options, { :a=>"aaa", :b=>"bbb", :name=>"テスト", :type=>"event" }
    assert_equals out2.options, { :name=>"テスト2", :type=>"graph" }

    out.set_properties( {:x=>"xxx", "a"=>"abc"} ) # 文字列をキーにしてもto_symされたものがキーにされる。
    out2.set_properties( {:y=>"yyy", :a=>"ab"} )

    assert_equals out.options, {:x=>"xxx", :a=>"abc", :b=>"bbb", :name=>"テスト", :type=>"event" }
    assert_equals out2.options, { :y=>"yyy", :a=>"ab", :name=>"テスト2", :type=>"graph" }

    #名前の更新
    @o.agent_name = "エージェント名2"
    assert_equals @o.agent_name, "エージェント名2"

    # 再作成 # 既存のデータがロードされる
    @o = JIJI::Output.new( "agent_id", @dir )
    list = read( @o.get("テスト"), nil, nil )
    assert_equals list, [
      ["type", "データ\nデータ", Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s],
      ["type2", "データ2\nデータ" , Time.local(2008, 8, 1, 12, 10, 20).to_i.to_s],
      ["type3", "データ3" , Time.local(2008, 8, 2, 10, 0, 0).to_i.to_s],
      ["type4", "データ4", Time.local(2008, 8, 3, 10, 0, 0).to_i.to_s]
    ]
    list = read( @o.get("テスト2"), nil, nil )
    assert_equals list, [
      ["100", "110", Time.local(2008, 8, 1, 10, 0, 0).to_i.to_s],
      ["200", "220", Time.local(2008, 8, 1, 12, 10, 20).to_i.to_s],
      ["10" , "20",  Time.local(2008, 8, 3, 10, 0, 0).to_i.to_s]
    ]
    assert_equals @o.agent_name, "エージェント名2"
    assert_equals @o.get("テスト").options, {:x=>"xxx", :a=>"abc", :b=>"bbb", :name=>"テスト", :type=>"event" }
    assert_equals @o.get("テスト2").options, { :y=>"yyy", :a=>"ab", :name=>"テスト2", :type=>"graph" }
    @o.each {|k, v|
      case k
      when "テスト"
        assert_equals v, @o.get("テスト")
      when "テスト2"
        assert_equals v, @o.get("テスト2")
      else
        fail
      end
    }
  end

  def read( out, start_date, end_date, scale=:raw )
    list = []
    out.each( scale, start_date, end_date ) {|row| list << row }
    return list
  end
end