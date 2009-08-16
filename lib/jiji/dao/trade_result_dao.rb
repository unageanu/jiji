
require 'thread'
require 'jiji/util/csv_append_support'
require 'jiji/util/thread_use_generator'
require 'jiji/util/util'
require 'jiji/models'
require 'jiji/dao/timed_data_dao'
require 'set'

module JIJI
  module Dao

    # 取引結果DAO
    class TradeResultDao

      def initialize( data_dir, scales=[] )
        @data_dir = data_dir
        @scales = scales

        aggregators = @scales.map {|s| TradeAggregator.new(s) }
        @trade_dao = dao( "trade", aggregators )

        aggregators = @scales.map {|s| LastAggregator.new(s) }
        @profit_or_loss_dao = dao( "profit_or_loss", aggregators )

        @position_dir = "#{data_dir}/positions"
        FileUtils.mkdir_p @position_dir unless File.exists? @position_dir
      end

      # ポジションデータを保存する
      def save( position )
        props = position.values
        file = "#{@position_dir}/#{position.position_id}.yaml"
        FileLock.new( file ).writelock {|f|
          f.write( YAML.dump(props) )
        }
      end
      # ポジションデータをロードする。
      def load( id )
        props = {}
        file = "#{@position_dir}/#{id}.yaml"
        if ( File.exist? file )
          FileLock.new( file ).readlock {|f|
            props = YAML.load f
          }
        end
        props
      end

      # 指定期間のトレードデータを得る。
      def list_positions( scale, start_date=nil, end_date=nil )
        ids = Set.new
        @trade_dao.each_data( scale, start_date, end_date ) {|r, t|
          ids += r[0].split(" ")
        }
        
        # バッファ内に取得期間内のデータがある場合、それも追加する。
        aggregator = @trade_dao.aggregator.find {|a| a.scale == scale }
        if  aggregator  && aggregator.values
           aggregator.values.each {|v|  ids << v  }
        end
        ids.inject({}) {|r,id| 
          v = load(id)
          if ( v && !( start_date && v[:fix_date] != 0 && v[:fix_date] < start_date.to_i ) \
            && !( end_date &&  v[:date]  > end_date.to_i ))
            r[id] = v
          end
          r 
        }
      end

      # 指定の期間の損益データを得る。
      def each( scale=:raw, start_date=nil, end_date=nil, &block )
        @profit_or_loss_dao.each_data( scale, start_date, end_date ) {|row, time|
          yield row
        }
      end

      # 取引結果を記録する。
      def next( operator, time )
        @profit_or_loss_dao << BasicTimedData.new(
          [operator.profit_or_loss, operator.fixed_profit_or_loss, operator.win_rate], time)
        ids = operator.positions.map {|p| p[1].position_id }
        @trade_dao << BasicTimedData.new( [ids], time)
      end

      # 取引結果を強制的に記録する。
      def flush( time )
        # 取引結果のみ(損益データは出力しない)
        @trade_dao.flush(time)
      end

    private

      def dao( name, aggregators )
        dir = "#{@data_dir}/#{name}"
        FileUtils.mkdir_p dir unless File.exists? dir

        TimedDataDao.new( dir, aggregators )
      end

      def lock(file)
        FileLock.new( "#{file}.lock" ).writelock {
          yield
        }
      end

      class TradeAggregator < AbstractAggregator
        def aggregate( timed_data )
          @values = Set.new unless @values
          @values += timed_data.values[0]
        end
        def aggregated
          begin
            str = @values.to_a.join(" ")
            return BasicTimedData.new( [str] \
              + [@start.to_i, @end.to_i], @end)
          ensure
            @values.clear if @values
          end
        end
        attr_reader :values
      end

    end
  end

end