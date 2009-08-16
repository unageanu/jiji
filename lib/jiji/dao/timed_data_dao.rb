require 'jiji/error'
require 'date'
require 'jiji/util/csv_append_support'
require 'jiji/util/file_lock'
require 'jiji/util/iterator'

module JIJI
  module Dao

    # 時間を持つデータ
    module TimedData
      def values
        []
      end
      attr :time, true
    end

    BasicTimedData = Struct.new( :values, :time )

    # 時間を持つデータをCSVで記録するためのDao
    # 　データの記録、
    # 　一定期間のデータの集約結果の記録、
    # 　一定期間のデータの読み込み、
    # をサポート。
    #
    class TimedDataDao

      DATE_FORMAT = "%Y-%m-%d"
      MONTHLY_DATE_FORMAT = "%Y-%m"

      def initialize( root_dir, aggregator=[] )
        @root_dir = root_dir
        @aggregator = aggregator
      end

      # 指定期間のデータを読み込む
      def each_data( scale=:raw, start_time=nil, end_time=nil, &block )
        sd = start_time || first_day( scale )
        ed = end_time || last_day( scale )

        it = ( !sd || !ed ) \
          ? EmptyIterator.new \
          : TimedDataIterator.new( scale, sd, ed, self )
        if block_given?
          it.each {|row|
            time = row.pop.to_i
            block.call( row, time )
          }
        else
          return it
        end
      end

      # データを強制的に書き込む
      # バックテストで取引が完了し場合に使用し、結果を表性的に書き出す。
      def flush( time )
        @aggregator.each {|ag|
          ag_dir = ag_dir(ag)
          ag.flush( time ) {|data|
            out( ag, ag_dir, data )
          }
        }
      end

      # データを追加する
      def <<(timed_data)
        @aggregator.each {|ag|
          ag_dir = ag_dir(ag)
          ag.next( timed_data ) {|data|
            out( ag, ag_dir, data )
          }
        }
      end

      # 利用可能なデータ一覧を得る
      def list_data_files( scale, pattern="*" )
        Dir.glob( "#{@root_dir}/#{scale.to_s}/#{pattern}.csv" ).map{|d| File.basename(d) }.sort!
      end
      # 利用可能な最後のデータ
      def last_day( scale )
        l = list_data_files( scale )
        return nil if l.empty?
        if TimedDataDao.dairy?(scale)
          to_time( l.last[0..-5], true ) + 24*60*60
        else
          to_time( l.last[0..-5], false ) + 24*60*60*31
        end
      end
      # 利用可能な最初のデータ
      def first_day( scale )
        l = list_data_files( scale )
        l.empty? ? nil : to_time( l.first[0..-5], TimedDataDao.dairy?(scale) )
      end
      # 利用可能な最後のデータ
      def last_time( scale )
        l = list_data_files( scale )
        return nil if l.empty?
        date = nil
        it = each_file_data( "#{@root_dir}/#{scale}/#{l.last}" )
        it.each { |row|
          date = row.last
        }
        date.to_i
      end
      # 利用可能な最初のデータ
      def first_time( scale )
        l = list_data_files( scale )
        return nil if l.empty?
        date = nil
        it = each_file_data( "#{@root_dir}/#{scale}/#{l.first}" )
        it.each { |row|
          date = row.last
          break
        }
        date.to_i
      end
      # 文字列を時刻に変換する
      def to_time( str, dairy=true )
        d = DateTime.strptime(str, dairy ? DATE_FORMAT : MONTHLY_DATE_FORMAT)
        Time.local( d.year, d.month, d.day )
      end
      # 時刻を日を示す文字列に変換する
      def to_date_str( time, dairy=true )
        time.strftime( dairy ? DATE_FORMAT : MONTHLY_DATE_FORMAT)
      end
      def self.dairy?(scale)
        scale.to_s =~ /^(raw|\d+[smh])$/
      end

      # 特定の日のデータを列挙する
      def each_dairy_data( scale, date, start_date=nil, end_date=nil)
        file = "#{@root_dir}/#{scale}/#{to_date_str(date, TimedDataDao.dairy?(scale))}.csv"
        each_file_data( file, start_date, end_date )
      end

      attr_reader :aggregator

    private

      # データを保存する
      def out( ag, ag_dir, data )
        date = to_date_str( data.time, TimedDataDao.dairy?(ag.scale) )
        file = "#{ag_dir}/#{date}.csv"
        CSV.open( file, 'a' ) {|w|
          w << ( data.values.map{|i|i.to_s} << data.time.to_i )
        }
      end

      # アグリゲーターが使用するデータ保存先ディレクトリを作成する。
      def ag_dir( ag )
        dir = "#{@root_dir}/#{ag.scale}"
        FileUtils.mkdir_p dir unless File.exist? dir
        return dir
      end

      # ファイルのデータを列挙する
      def each_file_data( file, start_date=nil, end_date=nil)
        return EmptyIterator.new  unless File.exist? file
        it =  CSVIterator.new( CSV.open( file, 'r' ) )
        return Filter.new( it ) {|row|
          time = row.last.to_i
          if start_date && time < start_date.to_i
            :next
          elsif end_date && time > end_date.to_i
            :break
          else
            :true
          end
        }
      end
    end

    # CSVReaderをIteratorにする。
    class CSVIterator < Iterator
      def initialize( reader )
        super()
        @reader = reader
        @item = @reader.shift
      end
      def next?
        !@item.empty?
      end
      def next
        begin
          @item
        ensure
          @item = @reader.shift
        end
      end
      def close
        @reader.close
      end
    end

    # 複数のCSVファイルのデータを順番に読み込む。
    class TimedDataIterator < Iterator
      def initialize( scale, start_time, end_time, dao )
        super()
        @dao = dao
        @start_time = start_time
        @end_time = end_time
        @scale = scale
        @current = start_time
        @current_date = Date.new( @current.year, @current.mon, \
          TimedDataDao.dairy?(@scale)  ? @current.day : 1 )
        next_iterator
      end
      def next?
        @it && @it.next?
      end
      def next
        begin
          @it.next
        ensure
          next_iterator unless @it.next?
        end
      end
      def close
        @it.close if @it
      end
      def next_iterator
        @it.close if @it
        @it = nil
        while ( @current.to_f <= @end_time.to_f )
          begin
            it = @dao.each_dairy_data( @scale, @current, @start_time, @end_time)
            if it != nil && it.next?
              @it = it
              return
            else
              it.close
            end
          ensure
            @current_date = TimedDataDao.dairy?(@scale) ? @current_date+1 : @current_date >> 1
            @current = Time.local(@current_date.year, @current_date.mon, @current_date.day)
          end
        end
      end
    end

    # 一定期間のデータを集約するクラス
    class Aggregator
      def initialize( scale )
        @scale = scale
      end
      # データを受け取り、集約したデータがある場合、それを引数としてブロックを実行する。
      def next( timed_data )
      end
      # 集約したデータがある場合、それを引数としてブロックを実行する。
      def flush( time )
      end
      attr_reader :scale
    end

    # 集約を行なわないAggregator
    class RawAggregator < Aggregator
      def initialize
        super("raw")
      end
      def next( timed_data )
        yield timed_data
      end
    end

    # 一定期間のデータを集約するクラス
    class AbstractAggregator < Aggregator
      def initialize( scale )
        super
        @period = JIJI::Util.parse_scale(scale)
        @next = nil
      end
      # データを受け取り、集約したデータがある場合、それを引数としてブロックを実行する。
      def next( timed_data )
        now = timed_data.time
        unless @next
          @next = Time.at(((now.to_i / @period)+1) * @period )
          @start = Time.at(@next.to_i-@period)
        end
        aggregate( timed_data )
        if now >= @next
          @end = @next
          yield aggregated
          @start = @next
          @end = nil
          @next += @period while @next <= now
        end
      end
      def flush( time )
        return unless @next #一度もnextが呼ばれていない場合、何もしない
        
        @end = time
        yield aggregated
        @start = @next
        @end = nil
        @next += @period while @next <= time
      end
      def aggregate( timed_data )
      end
      def aggregated
      end
      def next_date
        @next
      end
      attr_reader :start
    end

    # 平均を取るAggregator
    class AvgAggregator < AbstractAggregator
      def aggregate( timed_data )
        @values = [] unless @values
        timed_data.values.each_index {|i|
          @values[i] = [] unless @values[i]
          @values[i] << timed_data.values[i]
        }
      end
      def aggregated
        avgs = @values.map{|vs|
          vs.inject(0){|t,v| t+=v }/vs.length
        }
        @values = []
        BasicTimedData.new(avgs + [@start.to_i, @end.to_i], @end)
      end
    end

    # 最後の値を返すAggregator
    class LastAggregator < AbstractAggregator
      def aggregate( timed_data )
        @values = timed_data.values
      end
      def aggregated
        BasicTimedData.new( @values + [@start.to_i, @end.to_i], @end)
      end
    end

  end
end