
require 'thread'
require 'jiji/util/csv_append_support'
require 'jiji/util/util'
require 'jiji/models'
require 'jiji/dao/timed_data_dao'

module JIJI
  module Dao

    # レートDAO
    class RateDao

      def initialize( data_dir, scales=[] )
        @data_dir = data_dir
        @scales = scales
        @daos = {}
        @mutex = Mutex.new
      end

      # 所定の期間のレートデータを得る。
      def each( scale=:raw, pair=:USDJPY, start_date=nil, end_date=nil )
        dao( pair ).each_data( scale, start_date, end_date ) {|row,time|
           yield row
        }
      end

      # 所定の期間のすべての通貨ペアのレートデータを得る。
      def each_all_pair_rates( scale=:raw, start_date=nil, end_date=nil, &block )
        pairs = list_pairs
        its  = nil
        begin
          its = pairs.map {|p|
            dao(p).each_data( scale,start_date,end_date )
          }
          _each_all_pair_rates( pairs, its, &block )
        ensure
          its.each {|i| i.close } if its
        end
      end

      # 次のレートを追加する。
      def next_rates( rates )
        rates.each_pair {|pair,v|
          dao(pair) << v
        }
      end

      # ペアに対応するdaoを取得する
      def dao(pair)
        @mutex.synchronize {
          return @daos[pair] if @daos.key? pair

          dir = "#{@data_dir}/#{pair.to_s}"
          FileUtils.mkdir_p dir unless File.exists? dir

          aggregators = @scales.map {|s| RatesAggregator.new(s) }
          aggregators << RawRatesAggregator.new

          @daos[pair] = TimedDataDao.new( dir, aggregators )
          @daos[pair]
        }
      end

      def list_pairs
        list = []
        Dir.glob( "#{@data_dir}/*" ) {|d|
         next unless File.directory? d
         next unless d =~ /\/([A-Z]+)$/
         list << $1
        }
        list
      end

    private
      def _each_all_pair_rates( pairs, its )
        buff = PairBuffer.new
        exist_next = true
        while( exist_next )
          exist_next = false
          its.each_index {|index|
            it = its[index]
            if ( it.next? )
              # 末尾のデータはDAOで使うための日時指定で不要なので取り除く
              item = it.next
              item.pop
              buff.add( pairs[index],  item )
              exist_next = true
            else
              exist_next = exist_next || false
            end
          }
          yield buff.next if buff.next?
        end
        yield buff.next while buff.next?
      end


      class RatesAggregator < JIJI::Dao::AbstractAggregator
        def initialize( scale )
          super
        end
        def aggregate( timed_data )
          unless @rate
            @rate = PeriodicallyRate.new
            @rate.start_time = timed_data.time
          end
          @rate << timed_data
        end
        def aggregated
          @rate.end_time = @end
          vs = @rate
          @rate = PeriodicallyRate.new
          @rate.start_time = @end
          return vs
        end
      end

      class RawRatesAggregator < JIJI::Dao::Aggregator
        def initialize
          super( "raw" )
        end
        def next( timed_data )
          yield timed_data
        end
      end

      class PairBuffer
        def initialize
          @buff = {}
        end
        def add( pair, data )
          time = data.last.to_i
          @buff[time] = {} unless @buff[time]
          @buff[time][pair.to_sym] = data
        end
        def next?
          @buff.length > 0
        end
        def next
          keys = @buff.keys.sort!
          @buff.delete keys[0]
        end
      end

    end
  end

end