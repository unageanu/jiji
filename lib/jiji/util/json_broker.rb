#!/usr/bin/ruby --

require "json/lexer"
require "cgi"

module JSONBroker

# CGI向けAPI
# パラメータ「request」の値をリクエストとして使う。
class Cgi
  def self.invoke( service )
    print "Content-type: application/json\n\n"
    cgi =  CGI.new
    request = cgi.params["request"].to_s

    print Broker.new( service ).invoke( request )
  end
end

# JSONリクエストを元にサービスのAPIを実行して結果をJSONで返す。
#
# リクエスト:
# {"method":<サービスメソッド名>, "params":[<引数1>, <引数2>]}
#
# レスポンス(正常時):
# [{"error":null, "result":<実行結果>}]
#
# レスポンス(エラー時):
# [{"error":<例外の詳細>, "result":null}]
#
class Broker
  def initialize ( service )
    @service = service
  end

  def invoke ( request )
    begin
      json = JSON::Lexer.new(request).nextvalue
      method   = json["method"]
      args       = json["params"]

      result = @service.send( method.to_sym, *args )
      return '[{"error":null, "detail":null,"result":' << result.to_json << "}]"
    rescue Exception
      error =  $!.to_s.gsub(/'/, "")
      detail = $!.respond_to?(:detail) ? $!.detail : {}
      detail[:backtrace] =  $!.backtrace.join("\n").gsub(/'/, "")
      return '[{"error":' << error.to_json << ', "detail":' + detail.to_json + ', "result":null}]'
    end
  end
end

end

#print JSONBroker::Broker.new( "mii,aaa" ).invoke( '{"method":"to_s","params":[]}' )