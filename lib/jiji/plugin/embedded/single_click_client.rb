
require "rubygems"
require "clickclient"
require 'jiji/util/block_to_session'
require 'jiji/util/util'
require 'jiji/error'

# エラー発生時に実行時例外になる場合があるので修正。
module ClickClient
  def self.parse( content )
    doc = REXML::Document.new( content )
    unless ( doc.text( "./*/responseStatus" ) =~ /OK/  )
      error = doc.text( "./*/message" )
      raise "fail. #{error ? error : content }"
    end
    return doc
  end
end


module JIJI
  module Plugin

    #
    #==クリック証券へのアクセスを集約するためのサービス
    #
    class SingleClickClient
      include HTTPClient::Timeout

      def initialize( conf, logger )
        @conf = conf
        @logger = logger
        @mutex = Mutex.new
      end

      #リクエストを送付する。
      #ブロックの第1引数としてセッションが渡される。
      def request( &block )
        @mutex.synchronize {
          begin
            @session = create_session unless @session
            @session.request {|fx|
              timeout( conf[:timeout] || 60 ) {
                yield fx
              }
            }
          rescue Exception
            begin
              # セッション切れの場合、再作成して再実行してみる。
              # それでもエラーになったらあきらめてエラーを返す。
              if $!.to_s =~ /Out Of Session\./
                @logger.info "restart single click client."
                @session.close
                @session = create_session
                @session.request( &block )
              else
                raise $!
              end
            rescue Exception
              # エラーの場合、次回のリクエストもセッションを再作成する
              @session.close if @session
              @session = nil
              raise $!
            end
          end
        }
      end

      #サービスを破棄する。
      #不要になった場合、必ず実行すること。
      def close
        @session.close if @session
        @logger.info "close single click client."
      end
      attr :conf, true
      attr :logger, true

    private
      def create_session
        return Session.new { |wait|
          logger.info "start single click client."
          begin
            JIJI::Util.log_if_error_and_throw( @logger ) {
              proxy = nil
              if conf.key?(:proxy) && conf[:proxy] != nil && conf[:proxy].length > 0
                proxy = conf[:proxy]
              end
              client = ClickClient::Client.new( proxy )
              client.host_name = conf[:host] ? conf[:host] : "https://fx-demo.click-sec.com"
              @logger.info "connect host=#{client.host_name}, user=#{conf[:user]}"
              client.fx_session(conf[:user], conf[:password]){|fx|
                wait.call( fx )
              }
            }
          rescue Exception
            @logger.info "connect failed."
            e = JIJI::FatalError.new( JIJI::ERROR_NOT_CONNECTED, $!.to_s )
            wait.call( ErrorSession.new( e ) )
          end
        }
      end
    end

    #接続エラー時に使用するセッション
    #常にエラーをスローする。
    class ErrorSession
      def initialize(error)
        @error = error
      end
      def method_missing(name, *args, &block)
        raise @error
      end
    end

  end
end
