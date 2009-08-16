
require 'jiji/util/util'
require "jiji/dao/timed_data_dao"
require 'yaml'
require 'jiji/util/fix_yaml_bug'
require 'jiji/util/file_lock'
require 'fileutils'

module JIJI

  #===グラフデータの出力先を作成するためのクラス
  #エージェントでグラフを描画するには、JIJI::Output#getを呼び出してJIJI::GraphOutを取得し、グラフデータを出力します。
  # 
  # # output から出力先を作成。
  # @out = output.get( "移動平均線", :graph, {
  #   :column_count=>2, # データ数は2
  #   :graph_type=>:line, # 線グラフ
  #   :lines=>[30,40,50], # 30,40,50のメモリを描く
  #   :colors=>["#779999","#557777"] # デフォルトのグラフの色
  # })
  # ...(略)
  # 
  # # グラフのデータを出力。
  # # 出力先作成時にデータ数は2としているので、2つのデータを指定可能。
  # @out.put( 33, 39 )
  # @out.put( 45, 43 )
  # @out.put( 60, 69 )
  #
  class Output

    #プロパティファイル名
    PROPERTIES_FILE_NAME = "properties.yaml" #:nodoc:
    #メタ情報ファイル名
    META_FILE_NAME = "meta.yaml" #:nodoc:

    include Enumerable

    def initialize( agent_id, dir, scales=[] ) #:nodoc:
      @dir = "#{dir}/#{agent_id}" # 「ベースディレクトリ/エージェントID/出力名」に保存する。
      FileUtils.mkdir_p @dir

      @outs = {}
      @scales = scales
      @agent_id = agent_id

      # 既存データの読み込み
      DirLock.new( @dir ).writelock {
        Dir.glob( "#{@dir}/*" ) {|d|
          meta = "#{d}/#{META_FILE_NAME}"
          next unless File.directory? d
          next unless File.exist? meta
          props = YAML.load_file meta
          @outs[props[:name]] =
            create_output( d, props[:name], props[:type].to_sym, props )
        }
      }

      # 名前の読み込み
      file = properties_file
      if File.exist? file
        properties = YAML.load_file(file)
        @agent_name = properties[:agent_name]
      end
    end

    #エージェント名を設定する
    def agent_name=(name) #:nodoc:
      @agent_name = name
      FileLock.new( properties_file ).writelock { |f|
        f.write( YAML.dump({:agent_name=>name}) )
      }
    end

    #エージェント名を取得する
    def agent_name #:nodoc:
      @agent_name
    end

    #====グラフの出力先オブジェクトを取得します。
    #
    #name:: 名前(UIでの表示名)
    #type:: 種別。:graph を指定してください。
    #option:: 補足情報。以下が指定可能です
    #         - 「:column_count」 .. グラフのカラム数を整数値で指定します。(<b>必須</b>)
    #         - 「:graph_type」 .. グラフの種類を指定します。以下の値が指定可能です。
    #           - :rate ..  レート情報に重ねて表示(移動平均線やボリンジャーバンド向け)。グラフは、ローソク足描画領域に描画される。
    #           - :zero_base ..  0を中心線とした線グラフ(RCIやMACD向け)。グラフは、グラフ描画領域に描画される。
    #           - :line ..  線グラフとして描画する。(デフォルト)。グラフは、グラフ描画領域に描画される。
    #         - 「:colors」 .. グラフの色を「#FFFFFF」形式の文字列の配列で指定します。指定を省略した場合「0x557777」で描画されます。
    #return:: 出力先
    def get( name, type=:graph, options={} )
      raise "illegal Name. name=#{name}" if name =~ /[\x00-\x1F\x7F\\\/\r\n\t]/
      return @outs[name] if @outs.key? name
      DirLock.new( @dir ).writelock {
        sub_dir = "#{@dir}/#{JIJI::Util.encode(name).gsub(/\//, "_")}"
        FileUtils.mkdir_p sub_dir
        options[:type] = type.to_s
        options[:name] = name
        @outs[name] = create_output( sub_dir, name, type, options )
        @outs[name].time = time
        @outs[name].save
      }
      @outs[name]
    end

    # 出力先を列挙する
    def each( &block ) #:nodoc:
      @outs.each( &block )
    end

    # 出力先をが存在するか評価する
    def exist?( name ) #:nodoc:
      @outs.key? name
    end


    # 現在時刻を設定する
    def time=(time) #:nodoc:
      @time = time
      @outs.each_pair {|k,v|
        v.time = time
      }
    end
    # 現在時刻
    attr_reader :time  #:nodoc:
    # スケール
    attr :scales, true  #:nodoc:
    # エージェントID
    attr_reader :agent_id  #:nodoc:

  private
    # 出力先を作る
    def create_output( sub_dir, name, type, options )  #:nodoc:
      case type
        when :event
          EventOut.new( sub_dir, name, options )
        when :graph
          GraphOut.new( sub_dir, name, options, @scales )
        else
          raise "unkown output type."
      end
    end
    #プロパティ情報ファイルのパスを取得する
    def properties_file  #:nodoc:
      "#{@dir}/#{PROPERTIES_FILE_NAME}"
    end
  end

  #===出力先の基底クラス
  class BaseOut #:nodoc:

    include Enumerable

    # コンストラクタ
    def initialize( dir, name, options )
      @dir = dir
      @dao = JIJI::Dao::TimedDataDao.new( dir, aggregators )
      @options = options
    end

    # データを読み込む
    def each( scale=:raw, start_date=nil, end_date=nil, &block )
      @dao.each_data( scale, start_date, end_date ) { |row, time|
        yield row
      }
    end

    #プロパティを設定する。
    #props:: プロパティ
    def set_properties( props )
      props.each_pair {|k,v|
        @options[k.to_sym] = v
      }
      save
    end

    #設定値をファイルに出力
    def save
      FileLock.new("#{@dir}/#{JIJI::Output::META_FILE_NAME}" ).writelock { |f|
        f.write( YAML.dump(@options) )
      }
    end

    # 補足情報
    attr_reader :options
    # 現在時刻
    attr :time, true

  end

  # イベントデータの出力先
  class EventOut < BaseOut #:nodoc:
    # ログを書き込む
    def put( type, message )
      @dao << JIJI::Dao::BasicTimedData.new(
        [type.to_s, message, @time.to_i.to_s], @time)
    end
    def aggregators
      [JIJI::Dao::RawAggregator.new]
    end
  end

  #===グラフデータの出力先
  class GraphOut < BaseOut
    # コンストラクタ
    def initialize( dir, name, options, scales=[] ) #:nodoc:
      @scales = scales
      super( dir, name, options )
    end
    #====グラフデータを出力します。
    #numbers:: グラフデータ
    def put( *numbers )
      @dao << JIJI::Dao::BasicTimedData.new( numbers << @time.to_i, @time)
    end
    def aggregators #:nodoc:
      list = @scales.map{|s| JIJI::Dao::AvgAggregator.new s}
      list << JIJI::Dao::RawAggregator.new
    end
  end

end