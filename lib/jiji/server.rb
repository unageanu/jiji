
require 'jiji/registry'
require 'webrick'
require 'jiji/util/json_broker'
require 'cgi'

module JIJI
  
  class FxServer < WEBrick::HTTPServer
    def initialize( base, param={} )
      
      registry = JIJI::Registry.new(base, self)
      registry.server_logger.info "base dir : #{base}"
      
      # データ移行
      JIJI::Util.log_if_error_and_throw(registry.server_logger) {
        registry.migrator.migrate
      }
      # プラグイン
      registry.plugin_loader.load
      
      conf = registry[:conf]
      param[:Port] = conf.get([:server,:port], 7000).to_i 
      begin
        fork{}
        param[:ServerType] = WEBrick::Daemon
      rescue Exception
      end
      param[:MimeTypes] = WEBrick::HTTPUtils::DefaultMimeTypes.merge({"js"=>"application/javascript"})
      
      param[:Logger] = registry[:server_logger]  
      param[:DocumentRoot] = File.expand_path( "#{__FILE__}/../../../html" )
      param[:Logger].info( "document root: #{ param[:DocumentRoot] }"  )
      
      start_callback_org = param[:StartCallback]
      param[:StartCallback] = proc {
        JIJI::Util.log_if_error(registry.server_logger) {
	        registry.process_manager.start
	        [:INT,:TERM].each {|sig|
	          trap(sig){ shutdown }
	        }        
	        start_callback_org.call if start_callback_org
        }
      }
      stop_callback_org = param[:StopCallback]
      param[:StopCallback] = proc { 
        JIJI::Util.log_if_error(registry.server_logger) {
          begin
	          registry.process_manager.stop
	        ensure
            begin
              registry.permitter.close
            ensure
              registry.securities_plugin_manager.close
            end
          end
	        stop_callback_org.call if stop_callback_org
        }
      }
      super(param)
      
      mount("/json", JIJI::JsonServlet, registry)
    end
  end
  
  class JsonServlet < WEBrick::HTTPServlet::AbstractServlet
    
    # サーブレットの唯一のインスタンス
    @@instance = nil
    # インスタンス生成を同期化するためのMutex
    @@instance_creation_mutex = Mutex.new
    
    # サーブレットのインスタンスを生成するための関数
    def self.get_instance(config, *options)
      @@instance_creation_mutex.synchronize {
        @@instance = self.new(config, *options) if @@instance == nil
        @@instance
      }
    end
    
    def initialize( config, *options )
      super
      @registry = options[0]
    end
      
    def do_GET(req, res)
      begin
        process( req, res, req.query["request"].to_s )
      rescue Exception
        @registry.server_logger.error $!
        error =  $!.to_s + " : " + $!.backtrace.join("\n")
        res.body = "[{\"error\":\"fatal:#{error}\", \"result\":null}]"
      end
    end
    
    def do_POST(req, res)
      begin 
        process( req, res, CGI.unescape(req.body.to_s) )
      rescue Exception
        @registry.server_logger.error $!
        error =  $!.to_s + " : " + $!.backtrace.join("\n")
        res.body = "[{\"error\":\"fatal:#{error}\", \"result\":null}]"
      end
    end
    
    def process( req, res, request )
      res['Content-Type'] = "application/json"
      begin
        path = req.path
        @registry.server_logger.info "access : path=#{req.path}"
        raise "illegal path." unless path =~ /\/json\/([a-zA-Z0-9_]+)$/
        @registry.server_logger.info "access : request=#{request}"
        service = @registry["#{$1}_service".to_sym]
        raise "service not found." if service == nil
        res.body = JSONBroker::Broker.new( service ).invoke( request )
      rescue JIJI::UserError
        @registry.server_logger.warn $!
        error =  $!.to_s + " : " + $!.backtrace.join("\n")
        res.body = "[{\"error\":\"#{$!.code}:#{error}\", \"result\":null}]" 
      rescue JIJI::FatalError
        @registry.server_logger.error $!
        error =  $!.to_s + " : " + $!.backtrace.join("\n")
        res.body = "[{\"error\":\"#{$!.code}:#{error}\", \"result\":null}]"
      end
    end
  end
end