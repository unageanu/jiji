
require 'rubygems'
require 'yaml'
require 'jiji/util/fix_yaml_bug'
require 'needle'
require 'jiji/collector'
require 'jiji/configuration'
require 'jiji/observer'
require 'jiji/process'
require 'jiji/process_manager'
require 'jiji/agent/agent'
require 'jiji/agent/agent_manager'
require 'jiji/agent/agent_registry'
require 'jiji/agent/permitter'
require 'jiji/agent/util'
require 'jiji/output'
require 'jiji/output_manager'
require 'jiji/operator'
require "jiji/dao/file_system_dao"
require "jiji/dao/rate_dao"
require "jiji/dao/trade_result_dao"
require 'logger'
require 'fileutils'
require 'jiji/util/synchronize_interceptor'

require 'jiji/service/agent_service'
require 'jiji/service/hello_service'
require 'jiji/service/rate_service'
require 'jiji/service/trade_result_service'
require 'jiji/service/output_service'
require 'jiji/service/process_service'
require 'jiji/service/system_service'

require 'jiji/migration/migrator'
require 'jiji/migration/migrator1_0_3'
require 'jiji/migration/migrator1_1_0'
require 'jiji/migration/migrator1_2_0'

require 'jiji/plugin/plugin_loader'
require 'jiji/plugin/securities_plugin'

module JIJI

  #
  # レジストリ
  #
  class Registry

    def initialize(base, server=nil)
      @registry = Needle::Registry.new {|r|

        # ベースディレクトリ
        r.register( :base_dir) { base }
        # サーバー
        r.register( :server) { server }

        # 設定値
        r.register( :conf ) {
          JIJI::Configuration.new r.base_dir + "/conf/configuration.yaml"
        }
        # レート一覧置き場
        r.register( :rate_dir ) {
          dir = r.base_dir + "/" + r.conf.get([:dir,:rate_data], "rate_datas")
          FileUtils.mkdir_p dir
          dir
        }
        # プロセスデータ置き場
        r.register( :process_dir ) {
	        process_dir = "#{r.base_dir}/#{r.conf.get([:dir,:process_log], "process_logs")}"
	        FileUtils.mkdir_p process_dir
          process_dir
        }
        # エージェント置き場
        r.register( :agent_dir ) {
          agent = r.conf.get([:dir,:agent], "agents")
          FileUtils.mkdir_p "#{r.base_dir}/#{agent}"
          agent
        }
        r.register( :shared_lib_dir ) {
          shared_lib = r.conf.get([:dir,:shared_lib], "shared_lib")
          FileUtils.mkdir_p "#{r.base_dir}/#{shared_lib}"
          shared_lib
        }
        # 出力データ置き場
        r.register( :output_dir, :model=>:multiton_initialize ) {|c,p,id|
          dir = "#{r.process_dir}/#{id}/out"
          FileUtils.mkdir_p dir
          dir
        }

        # バージョンファイル
        r.register( :version_file ) {
          r.base_dir + "/data_version"
        }

        # ロガー
        r.register( :server_logger ) {
          dir = "#{r.base_dir}/#{r.conf.get([:dir,:log], "logs")}"
          FileUtils.mkdir_p dir
          l = Logger.new( dir + "/log.txt", 10, 512*1024 )
          l.level = Logger::DEBUG
          l
        }
        r.register( :process_logger, :model=>:multiton_initialize ) {|c,p,id|
          dir = "#{r.process_dir}/#{id}"
          FileUtils.mkdir_p dir
          c = Logger.new( dir + "/log.txt", 10, 512*1024 )
          r.permitter.proxy( c, [/^(info|debug|warn|error|fatal|close)$/] )
        }

        # Permitter
        r.register( :permitter ) {
          JIJI::Permitter.new( 5, 0 )
        }

        # Dao
        r.register( :scales ) {
          ["1m", "5m", "10m", "30m", "1h", "6h", "1d", "2d", "5d"]
        }
        r.register( :rate_dao ) {
          JIJI::Dao::RateDao.new( r.rate_dir, r.scales )
        }
        r.register( :trade_result_dao, :model=>:multiton_initialize ) {|c,p,id|
          dir = "#{r.process_dir}/#{id}/trade"
          FileUtils.mkdir_p dir
          JIJI::Dao::TradeResultDao.new( dir, r.scales )
        }
        r.register( :agent_file_dao ) {
          dir = "#{r.base_dir}/#{r.conf.get([:dir,:agent], "agents")}"
          sdir = "#{r.base_dir}/#{r.conf.get([:dir,:shared_lib], "shared_lib")}"
          FileUtils.mkdir_p dir
          FileUtils.mkdir_p sdir
          JIJI::Dao::FileSystemDao.new( r.base_dir )
        }

        # アウトプット
        r.register( :output_manager ) {
          JIJI::OutputManager.new(r)
        }
        r.register( :output, :model=>:multiton_initialize ) {|c,p,id,agent_id|
          dir = r.output_dir(id)
          c = JIJI::Output.new(agent_id, dir, r.scales)
          r.permitter.proxy( c, [/^(get|put|<<)$/], [/^get$/] )
        }

        # オブザーバー
        r.register( :rmt_observer_manager ) {
          JIJI::WorkerThreadObserverManager.new([
            r.rate_dao, r.agent_manager("rmt",true)
          ], r.process_logger("rmt"))
        }
        r.register( :backtest_observer_manager, :model=>:multiton_initialize ) {|c,p,id|
          JIJI::ObserverManager.new( [r.agent_manager(id, false)], r.process_logger(id))
        }

        # エージェントマネージャ
        r.register( :agent_manager, :model=>:multiton_initialize ) {|c,p,id,failsafe|
          c = JIJI::AgentManager.new( id, r.agent_registry, r.process_logger(id), failsafe )
          c.operator = r.operator(id, false, nil) # 作成段階では常に取引は行なわない。
          c.output_manager = r.output_manager
          c.conf = r.conf
          c.trade_result_dao = r.trade_result_dao(id)
          c
        }
        r.intercept( :agent_manager ).with {
          SynchronizeInterceptor
        }.with_options( :id=>:agent_manager )

        # エージェントレジストリ
        r.register( :agent_registry ) {
          c = JIJI::AgentRegistry.new( r.agent_dir, r.shared_lib_dir )
          c.conf = r.conf
          c.server_logger = r.server_logger
          c.file_dao = r.agent_file_dao
          c.load_all
          c
        }

        # オペレーター
        r.register( :operator, :model=>:multiton_initialize ) {|c,p,id,trade_enable,money|
          c = JIJI::RmtOperator.new(r.securities_plugin_manager.selected,
              r.process_logger(id), r.trade_result_dao(id), trade_enable, money)
          c.conf = r.conf
          r.permitter.proxy( c, [/^(sell|buy|commit)$/], [/^(sell|buy)$/])
        }

        # コレクター
        r.register( :rmt_collector ) {
          c = JIJI::Collector.new
          c.observer_manager = r.rmt_observer_manager
          c.conf      = r.conf
          c.logger    = r.process_logger("rmt")
          c.client    = r.securities_plugin_manager.selected
          c
        }
        r.register( :backtest_collector, :model=>:multiton_initialize ) {|c,p,id, start_date, end_date|
          c = JIJI::BackTestCollector.new( r.rate_dao, start_date, end_date )
          c.observer_manager = r.backtest_observer_manager(id)
          c.conf      = r.conf
          c.logger    = r.process_logger(id)
          c.client    = r.securities_plugin_manager.selected
          c
        }

        # RMTプロセス
        r.register( :rmt_process ) {
          id = "rmt"
          info = r.process_info( id )
          if info.data_exist?
            info.load
          else
            now = Time.now.to_i
            info.props = {
              "id"=>id,
              "name"=>"",
              "memo"=>"",
              "create_date"=>now,
              "start_date"=>now,
              "end_date"=>now,
              "agents"=>{},
              "state"=>:WAITING,
              "trade_enable"=>false
            }
          end
          c = JIJI::Process.new( info )
          c.agent_manager =  r.agent_manager(id,true)
          c.trade_enable = ( info["trade_enable"] == true )
          c.logger = r.process_logger(id)
          c.observer_manager = r.rmt_observer_manager
          c.collector = r.rmt_collector
          c
        }
        # バックテストプロセス
        r.register( :backtest_process, :model=>:prototype ) {|c,p,info|
          # 既存のバックテストを読み込む場合、プロパティはnil
          id = info.process_id
          c = JIJI::Process.new(info)
          c.agent_manager =  r.agent_manager(id,false)
          c.trade_enable = false
          info["trade_enable"] = false
          c.logger = r.process_logger(id)
          c.observer_manager = r.backtest_observer_manager(id)
          c.collector = r.backtest_collector(id,
            Time.at( info["start_date"]), Time.at( info["end_date"]))
          c
        }
        r.register( :process_info, :model=>:prototype ) {|c,p,id|
          JIJI::ProcessInfo.new(id, r.process_dir)
        }
        r.register( :back_test_process_executor ) {
          c = JIJI::BackTestProcessExecutor.new
          c.registry = r
          c
        }

        # プロセスマネージャ
        r.register( :process_manager ) {
          c = JIJI::ProcessManager.new( r )
          c.conf = r.conf
          c
        }
        r.intercept( :process_manager ).with {
          SynchronizeInterceptor
        }.with_options( :id=>:process_manager )

        # サービス
        r.register( :hello_service ) {
          JIJI::Service::HelloService.new
        }
        r.register( :agent_service ) {
          c = JIJI::Service::AgentService.new
          c.agent_registry = r.agent_registry
          c.dao = r.agent_file_dao
          c.process_manager = r.process_manager
          c.agent_dir = r.agent_dir
          c.shared_lib_dir = r.shared_lib_dir
          c.server_logger = r.server_logger
          c
        }
        r.register( :rate_service ) {
          c = JIJI::Service::RateService.new
          c.rate_dao = r.rate_dao
          c
        }
        r.register( :trade_result_service ) {
          c = JIJI::Service::TradeResultService.new
          c.process_manager = r.process_manager
          c.registry = r
          c
        }
        r.register( :output_service ) {
          c = JIJI::Service::OutputService.new
          c.process_manager = r.process_manager
          c.process_dir = r.process_dir
          c.output_manager = r.output_manager
          c
        }
        r.register( :process_service ) {
          c = JIJI::Service::ProcessService.new
          c.process_manager = r.process_manager
          c
        }
        r.register( :system_service ) {
          c = JIJI::Service::SystemService.new
          c.server = r.server
          c
        }

        # データ移行
        r.register( :migrator ) {
          c = JIJI::Migration::Migrator.new
          c.registry = r
          c.server_logger = r.server_logger
          c.version_file = r.version_file
          c.migrators = [
            { :version=>Gem::Version.new( "1.0.3" ), :migrator=>JIJI::Migration::Migrator1_0_3.new},
            { :version=>Gem::Version.new( "1.1.0" ), :migrator=>JIJI::Migration::Migrator1_1_0.new},
            { :version=>Gem::Version.new( "1.2.0" ), :migrator=>JIJI::Migration::Migrator1_2_0.new}
          ]
          c
        }

        # プラグイン
        r.register( :plugin_loader ) {
          c = JIJI::Plugin::Loader.new
          c.server_logger = r.server_logger
          c
        }
        # Securitiesプラグイン
        r.register( :securities_plugin_manager ) {
          c = JIJI::Plugin::SecuritiesPluginManager.new
          c.conf = r.conf
          c.server_logger = r.server_logger
          c
        }
      }
    end

    def method_missing(name, *args)
      @registry.send( name, *args )
    end

    def [](name)
      @registry[name]
    end

  end

end