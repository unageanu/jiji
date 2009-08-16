
require 'rubygems'
require "highline"
require 'logger'
require 'jiji/server'
require 'jiji/util/json_rpc_requestor'
require 'jiji/plugin/plugin_loader'
require 'jiji/plugin/securities_plugin'

module JIJI

  # コマンドラインツール
  class Command

    # 設定ファイル置き場
    JIJI_DIR_NAME = "~/.jiji"


    # サービスを開始
    def start
      begin
        puts "jiji started."
        s = JIJI::FxServer.new( data_dir )
        s.start
      rescue Exception
        puts "[ERROR] start failed.(#{$!.to_s})"
        return
      end
    end

    # サービスを停止
    def stop
      begin
        host = ARGV[1] || "localhost"
        conf = JIJI::Registry.new(data_dir)[:conf]
        port = conf.get([:server,:port], 7000).to_i
        service = JSONBroker:: JsonRpcRequestor.new( "system", "http://#{host}:#{port}" )
        service.shutdown
        sleep 10 # 停止完了を待つ。
        puts "jiji stopped."
      rescue Exception
        puts "[ERROR] stop failed.(#{$!.to_s})"
        return
      end

    end

    # 初期化
    def setting
      h = HighLine.new
      
      # アクセス先証券会社
      JIJI::Plugin::Loader.new.load
      mng = JIJI::Plugin::SecuritiesPluginManager.new
      plugins = mng.all
      index = 0
      str = plugins.map {|p| "#{index+=1} : #{p.display_name.to_s}" }.join( "\n    " ) 
      value = h.ask("> Please select a securities.\n    " + str)
      unless value =~ /\d+/
        puts "[ERROR] setting failed.( Illegal value. vlaue=#{value} )"
        return
      end
      begin
        type = plugins[value.to_i-1]
        unless type
          puts "[ERROR] setting failed.( Illegal value. vlaue=#{value} )"
          return
        end
      rescue Exception
        puts "[ERROR] setting failed.( Illegal value. vlaue=#{value} )"
        return
      end
      
      # 入力
      values = {:type=>type.plugin_id}
      type.input_infos.each {|i|
         value = i.secure ? h.ask("> #{i.description}") {|q| q.echo = '*' } : h.ask("> #{i.description}")
         if i.validator && error = i.validator.call( value )
           puts "[ERROR] setting failed.( #{error}. value=#{value} )"
           return
         end
         values[i.key.to_sym] = value
      }
      dir  = h.ask("> Please input a data directory of jiji. (default: #{JIJI_DIR_NAME} )")
      dir = !dir || dir.empty? ? JIJI_DIR_NAME : dir

      port = h.ask('> Please input a server port. (default: 7000 )')
      port = !port || port.empty? ? "7000" : port
      unless port =~ /\d+/
        puts "[ERROR] setting failed.( illegal port number. port=#{port} )"
        return
      end

      # ディレクトリ作成
      begin
        puts ""
        ex_dir = File.expand_path(JIJI_DIR_NAME)
        mkdir ex_dir
        open( "#{ex_dir}/base", "w" ) {|f|
          f << dir
        }
        puts "create. #{ex_dir}/base"

        # ベースディレクトリの作成
        dir = File.expand_path(dir)
        mkdir(dir) if ( dir != ex_dir )
        mkdir("#{dir}/conf")

        # 設定ファイル
        open( "#{dir}/conf/configuration.yaml", "w" ) {|f|
          f << YAML.dump( {
            :server => { :port=>port.to_i },
            :securities => values
          } )
        }
        FileUtils.chmod(0600, "#{dir}/conf/configuration.yaml")

        # サンプルエージェント
        copy_base_files( dir, h  )
      rescue Exception
        puts "[ERROR] setting failed.(#{$!.to_s})"
        return
      end

      puts "Setting was completed!"
    end


    def run( args )
      case  args[0]
        when "start"; start
        when "stop";  stop
        when "setting"; setting
        when "restart"
          stop
          start
        else
          name = File.basename( File.expand_path( $0 ))
          puts "usage : #{name} ( setting | start | stop | restart )"
      end
    end

  private
    #サンプルのエージェント、共有ライブラリをコピーする。
    def copy_base_files( dir, h  )
      src_dir = File.expand_path("#{__FILE__}/../../../base/")
      files = []
      ["agents","shared_lib"].each {|d| 
        files += Dir.glob(File.expand_path("#{src_dir}/#{d}/**/*")).reject {|i|
          File.directory? i
        }
      }
      overwrite = :yes
      files.each {|f|
        new_path = f.sub( /#{src_dir}/, dir )
        if File.exist?(new_path) && overwrite != :all
          overwrite = ask_overwrite( h, new_path )
        else
          overwrite = overwrite != :all ? :yes : :all
        end
        if overwrite != :no
          mkdir( File.dirname( new_path ) )
          copy( f, new_path )
        end
      }
    end
    #上書きするかどうか確認する。
    def ask_overwrite( h, f )
      result = nil
      while ( !result )
        tmp = h.ask("> File #{f} is already exist. Do you want to overwrite? ([y]es/[n]o/[a]ll files)")
        next if !tmp || tmp.length == 0
        result = case tmp[0,1].downcase
          when "y";  :yes
          when "n";  :no
          when "a";  :all
        end
      end
      result
    end
  
    # データディレクトリを得る
    def data_dir
      base = "#{File.expand_path(JIJI_DIR_NAME)}/base"
      unless File.exist?( base  )
        raise "'#{base}' is not found. You need to run 'jiji setting'."
      end
      return File.expand_path(IO.read( base  ))
    end
    # ディレクトリを作る。
    def mkdir( path )
      return if File.exist? path
      FileUtils.mkdir_p path
      FileUtils.chmod(0755, path)
      puts "create. #{path}"
    end
    # ファイルをコピーする。
    def copy( path, to )
      FileUtils.copy( path, to )
      FileUtils.chmod(0644, to)
      puts "create. #{to}"
    end
  end
end