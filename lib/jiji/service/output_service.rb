module JIJI
  module Service
    class OutputService

      # 指定範囲の出力データを取得する。
      def list_datas( process_id, names, scale, start_time, end_time )
        map = output_manager.get_process_map( process_id )
        list = {}
        names.each {|n|
	        buff = []
          outputs = map[n[0]]
	        next unless outputs
          outputs.get(n[1]).each( scale,
            Time.at(start_time), Time.at(end_time) ) {|data|
	          buff << data
	        }
          list[n[0]] ||= {}
          list[n[0]][n[1]] = buff
        }
        return list
      end

      # プロセスの出力一覧を取得する
      def list_outputs( process_id )
        buff = {}
        rmt_process = nil
        rmt_process = process_manager.get( process_id )  if ( process_id == "rmt" )
        output_manager.each( process_id ) {|outputs|
          buff[outputs.agent_id] = {
            "agent_id"=>outputs.agent_id,
            "agent_name"=>outputs.agent_name,
            "outputs"=>outputs.inject({}) {|r,v|
              r[v[0]] = v[1].options
              r
            },
            "alive"=> process_id == "rmt" && 
              is_live_agent( rmt_process["agents"], outputs.agent_id )
          }
        }
        buff
      end

      # プロセスの出力を削除する
      def delete_output( process_id, agent_id )
        output_manager.delete( process_id, agent_id )
        :success
      end

      # アウトプットのプロパティを設定
      def set_properties( process_id, agent_id, output_name, properties )
        outputs = output_manager.get( process_id, agent_id )
        unless outputs.exist? output_name
          raise UserError.new( JIJI::ERROR_NOT_FOUND, "output not found. name=#{agent_id}:#{output_name}")
        end
        out = outputs.get(output_name)
        out.set_properties( properties )
        return :success
      end

      # プロセスのログを取得する
      def get_log( process_id )
        process_manager.get( process_id ) # プロセスの存在確認
        file = "#{@process_dir}/#{process_id}/log.txt" # TODO 古いものも連結するか? サイズが大きくなってしまうので微妙。
        if ( File.exist?( file ) )
          return IO.read( file )
        else
          return ""
        end
      end

      attr :process_dir, true
      attr :process_manager, true
      attr :output_manager, true
    private
      def is_live_agent( agents, agent_id )
        return false if !agents
        return agents.find {|i| i["id"] == agent_id }  != nil
      end
	  end

  end
end