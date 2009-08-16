
require 'jiji/error'

module JIJI
  module Service
	  class SystemService
      # サーバーを停止する。
      def shutdown
        @server.shutdown
      end
      attr :server, true
    end
  end
end