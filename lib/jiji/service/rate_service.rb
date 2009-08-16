module JIJI
  module Service
    class RateService

      # 指定範囲のレートを取得する。
      def list( pair, scale, start_time, end_time )
        buff = []
        @rate_dao.each( scale, pair.to_sym, Time.at(start_time), Time.at(end_time) ) {|data|
          buff << [data[0].to_f, data[1].to_f, data[2].to_f,
            data[3].to_f,data[16].to_i, data[17].to_i]
        }
        return buff
      end
      
      # 利用可能な通貨ペアの一覧を取得する。
      def pairs
        @rate_dao.list_pairs
      end

      # 利用可能なレートの開始日時/終了日時を得る。
      def range( pair )
        dao = @rate_dao.dao( pair )
        { :first=>dao.first_time(:raw).to_i,
         :last=>dao.last_time(:raw).to_i }
      end

      # 指定した月で利用可能な日の一覧を得る。
      def enable( pair, year, month )
        dao = @rate_dao.dao( pair )
        datas = dao.list_data_files( :raw, "#{year}-#{sprintf("%02d", month)}" )
        datas.map {|d| d[-2,2] }
      end

      attr :rate_dao, true
	  end

  end
end