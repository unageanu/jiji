module JIJI
  module Service
    class TradeResultService
      
      # 指定範囲のトレード結果を取得する。
      def list( process_id, scale, start_time, end_time )
        dao = registry.trade_result_dao(process_id)
        result = dao.list_positions( scale, start_time ? Time.at(start_time) : nil, end_time ? Time.at(end_time) : nil )
        # 現在進行中の建て玉はoperatorから取得する
        op = (process_id == "rmt") ? registry.rmt_process.agent_manager.operator : nil
        return result.map {|e|
          op && op.positions.key?(e[0]) ? op.positions[e[0]].values : e[1] 
        }
      end
      
      # 指定範囲の損益を取得する。
      def list_profit_or_loss( process_id, scale, start_time, end_time )
        dao = registry.trade_result_dao(process_id)
        buff = []
        dao.each( scale, start_time ? Time.at(start_time) : nil, end_time ? Time.at(end_time) : nil ) {|data|
          buff << data
        }
        return buff
      end
      
      attr :process_manager, true
      attr :registry, true
	  end
    
  end
end