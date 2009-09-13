require "rubygems"
require "jiji/util/json_rpc_requestor"
require 'uuidtools'

module JIJI
  
  #==jijiに接続してバックテストの実行と結果の取得を行うためのユーティリティ。
  #jijiのJSON-RPC APIを利用してバックテストの実行と結果の取得を行うユーティリティです。
  #
  # require 'rubygems'
  # require 'jiji/util/backtester'
  # 
  # #接続先のjijiを指定して、テスターを作成
  # tester = JIJI::BackTester.new( "http://unageanu.homeip.net/jiji-demo"  )
  # 
  # #エージェントを作成
  # agents = []
  # agents << tester.create_agent( "MovingAverageAgent", "moving_average_agent.rb",
  #  "移動平均_12-36", {"long"=>36,"period"=>10,"short"=>12})
  # agents << tester.create_agent( "MovingAverageAgent", "moving_average_agent.rb",
  #  "移動平均_25-75", {"long"=>75,"period"=>10,"short"=>25})
  # 
  # #テストを実行
  # time = Time.local(2009, 8, 20).to_i
  # process_id = tester.regist_test( "移動平均テスト2", "", time, time+24*60*60*3, agents )
  # 
  # #テストの実行完了を待つ
  # tester.wait( process_id )
  # 
  # #結果を確認
  # result = tester.get_result( process_id )
  # result.each_pair {|k,v|
  #   puts "\n---#{k}"
  #   puts "profit or ross : #{v.profit_or_loss}" 
  #   puts "positions : "
  #   v.positions.each {|p|
  #     puts "  #{p["pair"]} #{p["sell_or_buy"]} #{p["profit_or_loss"]}"
  #   }
  # }
  #
  class BackTester
    
    #===コンストラクタ
    #endpoint:: 接続先サーバーを示すエンドポイント 例) http://unageanu.homeip.net/jiji-demo
    def initialize( endpoint )
      @agent_service = JSONBroker::JsonRpcRequestor.new("agent", endpoint)
      @process_service = JSONBroker::JsonRpcRequestor.new("process", endpoint)
      @trade_result_service = JSONBroker::JsonRpcRequestor.new("trade_result", endpoint)
      @agents = @agent_service.list_agent_class
    end
    #===エージェントの情報を取得する。
    #class_name:: クラス名
    #file:: クラスが定義されているファイル名
    #return:: エージェントの情報/対応するエージェントがなければnil
    def get_agent_info( class_name, file )
      return @agents.find{|i|
        i["class_name"]==class_name && i["file_name"]==file
      }
    end
    
    #===バックテストに登録するためのエージェント情報を作成する。
    #class_name:: クラス名
    #file:: クラスが定義されているファイル名
    #name:: エージェント名
    #properties:: エージェントのプロパティ
    #return:: バックテストに登録するためのエージェント情報
    def create_agent( class_name, file, name,  properties )
      info = get_agent_info( class_name, file )
      raise "agent not found." unless info
      agent = info.dup
      agent["id"] = UUIDTools::UUID.random_create().to_s
      agent["class"] = "#{info["class_name"]}@#{info["file_name"]}"
      agent["name"] = name
      agent["property_def"] = agent["properties"].inject({}){|r,i|
        r[i["id"]] = i
        r
      }
      agent["properties"] = properties
      return agent
    end
    #===バックテストを実行する。
    #title:: テストの名前
    #memo:: メモ
    #start_time:: 開始日時(UNIXタイム/1970-01-01からの秒数)
    #end_time:: 終了日時(UNIXタイム/1970-01-01からの秒数)
    #agents:: 実行するエージェントの配列
    #return:: バックテストの識別ID(process_id)
    def regist_test( title, memo, start_time, end_time, agents )
      return @process_service.new_test( 
        title, memo, start_time, end_time, agents )["id"]
    end
    #===バックテストの完了を待つ
    #process_id:: バックテストの識別ID
    def wait( process_id ) 
      while ( true )
        status = @process_service.status( [process_id] )[0]["state"]
        return if status == "ERROR_END" || status == "FINISHED" || status == "CANCELED"        
        sleep 5
      end
    end
    #===バックテストの実行結果を取得する。
    #process_id:: バックテストの識別ID
    #return:: エージェント名をキーとする実行結果のハッシュ
    def get_result( process_id )
      result = @trade_result_service.list( process_id, "5d", nil, nil )
      return result.inject({}) {|r, item|
        info = r[item["trader"]] ||= Result.new( 0, [] )
        info.profit_or_loss += item["profit_or_loss"]
        info.positions << item
        r
      }
    end
    #実行結果
    Result = Struct.new( :profit_or_loss, :positions )
  end
end