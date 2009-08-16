module JIJI
  module Service
    class ProcessService

      # プロセス一覧を取得する。
      def list_test( )
        buff = []
        @process_manager.each {|p|
          buff << extract_properties( p )
        }
        return buff.sort_by {|item| item["create_date"] * -1 }
      end

      # プロセスを取得する。
      def get( process_id )
        p = @process_manager.get( process_id )
        process_info = extract_properties( p )
        process_info["agents"] = p["agents"] # getの場合はエージェントのプロパティも返す。
        return process_info
      end

      # プロセスの設定を更新する。
      def set( process_id, setting )
        @process_manager.set( process_id, setting )
      end


      # 新しいテストを作成&開始する
      def new_test( name, memo, start_date, end_date, agents )
        @process_manager.create_back_test(
          name, memo, start_date, end_date, agents );
      end

      # テストの状態を取得する
      def status( process_ids=[] )
        process_ids.inject([]) {|buff,id|
          p = @process_manager.get( id )
          buff << extract_properties( p )
        }
      end

      # テストを削除する
      def delete_test( process_id )
        @process_manager.delete_back_test( process_id )
      end

      # テストの実行をキャンセルする
      def stop( process_id, agent_properties )
        @process_manager.get( process_id ).stop
        :success
      end

      # テストを再実行する
      def restart( process_id, agent_properties )
        @process_manager.restart_test(process_id, agent_properties)
      end

      attr :process_manager, true
    private
      def extract_properties( process )
          return {
            "id"=>process["id"],
            "name"=>process["name"],
            "memo"=>process["memo"],
            "start_date"=>process["start_date"],
            "end_date"=>process["end_date"],
            "create_date"=>process["create_date"],
            "trade_enable"=>process["trade_enable"],
            "state"=>process["state"],
            "progress"=>process.progress
          }
      end
	  end

  end
end