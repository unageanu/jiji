#!/usr/bin/ruby --

require "cgi"
require 'httpclient'
require "json/lexer"
require "json/objects"

module JSONBroker

# クライアント
class JsonRpcRequestor
  def initialize( name, host="http://localhost:8080", proxy=nil )
    @client = HTTPClient.new( proxy, "JsonClientLib")
    @client.set_cookie_store("cookie.dat")
    @name = name
    @host = host
  end
  def method_missing( name, *args )
    body = CGI.escape("{\"method\":#{name.to_s},\"params\":#{args.to_json}}")
    result = @client.post("#{@host}/json/#{@name}", body )
    json = JSON::Lexer.new(result.content).nextvalue[0]
    if json["error"]
      raise json["error"]
    else
      json["result"]
    end
  end
end

end