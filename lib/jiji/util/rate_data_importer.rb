
require 'kconv'
require 'rubygems'
require 'mechanize'
require 'zip/zip'
require 'tmpdir'
require 'jiji/registry'

module JIJI

  #
  #==クリック証券のヒストリカルデータダウンロードサービスから為替レートデータを取得するユーティリティ
  #
  module Download

    #===ダウンロードを行うためのセッションを開始する
    #userId:: クリック証券のユーザーID
    #password:: ログインパスワード
    #proxy:: プロキシ
    def self.session( userid, password, proxy=nil )
      client = WWW::Mechanize.new {|c|
        # プロキシ
        if proxy
          uri = URI.parse( proxy )
          c.set_proxy( uri.host, uri.port )
        end
      }
      client.keep_alive = false
      client.max_history=0
      client.user_agent_alias = 'Windows IE 7'

      # ログイン
      page = client.get("https://sec-sso.click-sec.com/loginweb/")
      raise "Unexpected Error" if page.forms.length <= 0
      form = page.forms.first
      form.j_username = userid
      form.j_password = password
      client.submit(form, form.buttons.first)
      session = Session.new( client )
      if block_given?
        begin
          return yield( session )
        ensure
          session.logout
        end
      else
        return session
      end
    end
    class Session
      def initialize( client )
        @client = client
      end
      #===CSVデータをダウンロードする
      #yesr:: 年
      #month:: 月
      #pair:: 通貨ペア
      #to:: ダウンロード先ディレクトリ
      def download( year, month, pair, to="./" )
        FileUtils.makedirs(to)
        file = "#{to}/#{pair}_#{year}_#{month}.zip"
        result = @client.get("https://tb.click-sec.com/fx/historical/historicalDataDownload.do?" +
          "y=#{year}&m=#{sprintf("%02d", month)}&c=#{C_MAP[pair]}&n=#{pair}" )
        open( file, "w" ) {|w| w << result.body }
        extract( file, "#{to}" )
        FileUtils.rm(file)
      end
      #===ログアウトする
      def logout
        @client.get("https://sec-sso.click-sec.com/loginweb/sso-logout")
      end
      #===zipファイルを展開する。
      #zip:: zipファイル
      #dest:: 展開先ディレクトリ
      def extract( zip, dest )
        FileUtils.makedirs(dest)
        Zip::ZipFile.foreach(zip) {|entry|
          if entry.file?
            FileUtils.makedirs("#{dest}/#{File.dirname(entry.name)}")
            entry.get_input_stream {|io|
              open( "#{dest}/#{entry.name}", "w" ) {|w|
                while ( bytes = io.read(1024))
                  w.write bytes
                end
              }
            }
          else
            FileUtils.makedirs("#{dest}/#{entry.name}")
          end
        }
      end
      C_MAP = {
        :USDJPY=>"01", :EURJPY=>"02", :GBPJPY=>"03",
        :AUDJPY=>"04", :NZDJPY=>"05", :CADJPY=>"06",
        :CHFJPY=>"07", :ZARJPY=>"08", :EURUSD=>"09",
        :GBPUSD=>"10", :AUDUSD=>"11",:EURCHF=>"12",
        :GBPCHF=>"13", :USDCHF=>"14"
      }
    end
    PAIRS = [        
      :USDJPY, :EURJPY, :GBPJPY, :AUDJPY, :NZDJPY, :CADJPY,
      :CHFJPY, :ZARJPY, :EURUSD, :GBPUSD, :AUDUSD,:EURCHF,
      :GBPCHF, :USDCHF
    ]
  end

  class Converter

    def initialize( )
      @registry = JIJI::Registry.new( "./" )
    end

    #===展開したCSVデータをjijiの形式にフォーマットする。
    #csv_dir:: csvデータ置き場
    #to:: CSVデータ
    def convert( dir, to )
      FileUtils.mkdir_p to
      dao = @registry.rate_dao
      dao.instance_variable_set(:@data_dir, to)
      # CSVを読みつつデータを作成
      each_rate(dir) {|rates|
        dao.next_rates( rates )
      }
    end
    def each_rate(dir, &block)
      yyyymm = Dir.entries( dir ).reject{|d| !(d=~ /\d{6}/)  }.sort
      yyyymm.each {|ym|
        1.upto(31).each {|d|
          readers = {}
          begin 
            JIJI::Download::Session::C_MAP.each {|p|
              file = "#{dir}/#{ym}/#{p[0]}_#{ym}#{sprintf("%02d", d)}.csv"
              next unless File.exist? file
              readers[p[0]] = PushBackReader.new(CSV.open( file, 'r' ))
              readers[p[0]].shift # 最初のデータはヘッダーなので除外
            }
            next if readers.empty?
            read( readers, &block )
          ensure
            readers.each {|p| 
              begin
                p[0].close
              rescue; end
            }
          end
        }
      }
    end
    def read( readers )
      while( true )
        first = nil
        readers.each {|p|
          line = p[1].shift
          p[1].unshift line
          next if !line || line.length < 5
          next unless line[0] =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/
          first = !first || first.to_i > line[0].to_i ? line[0] : first
        }
        return unless first
        buff = readers.inject([]) {|r,p|
          line = p[1].shift
          next r if !line || line.length < 5
          if ( line[0] != first)
            p[1].unshift line
            next r
          end
          0.upto(3) {|i|
            time = Time.local( $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, i*10 )
            map = r[i] || r[i] = {}
            bid = line[i+1].to_f
            map[p[0].to_sym] = Rate.new( bid, bid+SPREAD[p[0].to_sym], 0, 0, time )
          }
          r
        }
        return if !buff || buff.empty?
        buff.each {|e|
          yield Rates.new( {}, e, e[:USDJPY].time )
        }
      end
    end
    SPREAD = {
      :AUDJPY => 0.02, :GBPUSD => 0.0003, :NZDJPY => 0.024,
      :AUDUSD => 0.0003, :CADJPY => 0.03, :EURCHF => 0.0003,
      :USDJPY => 0.008, :CHFJPY => 0.03,:GBPCHF => 0.0004, 
      :EURJPY => 0.014,:ZARJPY => 0.04,:USDCHF => 0.0004,
      :GBPJPY => 0.024,:EURUSD => 0.00016
    }
  end
  class PushBackReader
    def initialize( reader )
      @reader = reader
      @buff = []
    end
    def shift
      @buff.empty? ? @reader.shift : @buff.shift
    end
    def unshift(v)
      @buff.unshift v
    end
    def close
      @reader.close
    end
  end
end

puts "start download. #{Time.now}"
JIJI::Download.session( ARGV[0], ARGV[1] ) {|s|
  ARGV[3].to_i.upto( ARGV[4].to_i ) {|month|
  JIJI::Download::PAIRS.each {|pair|
      s.download( ARGV[2], month, pair, "./tmp" )
      puts "downloaded. #{ARGV[2]}/#{sprintf("%02d", month)} #{pair}"
    }
  }
}
puts "end download. #{Time.now}"
puts "start convert. #{Time.now}"
converter = JIJI::Converter.new
converter.convert( "./tmp", "./converted" )
puts "end convert. #{Time.now}"