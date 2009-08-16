
$: << "../lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/configuration'
require 'jiji/plugin/securities_plugin'
require 'fileutils'
require 'logger'
require 'jiji/util/json_rpc_requestor'

# テスト用ユーティリティなど。
module Test
  module Constants

    USER="<user-name>"
    PASSWORD="<password>"

    # テスト用設定値
    CONF = JIJI::Configuration.new

    Info = Struct.new( :trade_unit )
    Rate = Struct.new( :bid, :ask, :sell_swap, :buy_swap, :date )

  end

  # テスト用クライアント
  class MockClient
    include JIJI::Plugin::SecuritiesPlugin
    def plugin_id; :mock end
    def list_pairs
      [ Pair.new( :EURJPY, 10000 ), Pair.new( :USDJPY, 10000 ) ]
    end
    def list_rates
      {:EURJPY=>Rate.new( 102.01, 102.05, 100, -100 ),
       :USDJPY=>Rate.new( 102.01, 102.05, 100, -100 )}
    end
  end

  # サービスのテストの抽象基底クラス
  class AbstractServiceTest < RUNIT::TestCase
    def setup
    end
    def teardown
    end
  end

  #レジストリを破棄する。
  def self.destry( registry, dir=nil )
    begin
      registry.process_manager.stop
    ensure
      begin
        begin
          registry.permitter.close
        ensure
          registry.server_logger.close
        end
      ensure
        if dir
          FileUtils.rm_rf "#{dir}/logs"
          FileUtils.rm_rf "#{dir}/process_logs"
          FileUtils.rm_rf "#{dir}/rate_datas"
        end
      end
    end
  end

  # テスト用エージェント
  class Agent
    include JIJI::Agent

    @@fail_propset = proc{ |a| false }

    def initialize( cl, properties )
      @cl = cl
      @properties = properties
    end

    # 設定されたプロパティを取得する
    def properties
      @properties
    end
    # プロパティを設定する
    def properties=( properties )
      raise "test" if @@fail_propset.call( self )
      @properties = properties
    end
    def output
      ["out1","out2"]
    end
    attr :cl, true

    def self.set_fail_propset(&block)
      @@fail_propset = block
    end
  end

  #エージェントレジストリのモック
  class RegistryMock
    @@fail_create = proc{ |cl,p| false }
    def create( cl, property )
      raise "test" if @@fail_create.call( cl, property )
      Agent.new( cl, property ).taint
    end
    def self.set_fail_create(&block)
      @@fail_create = block
    end
  end

end