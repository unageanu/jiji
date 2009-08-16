
require 'jiji/error'
require 'jiji/agent/agent'
require 'jiji/agent/agent_manager'
require 'jiji/agent/agent_registry'
require 'jiji/agent/permitter'
require 'jiji/agent/util'


module JIJI
  module Service
    class AgentService

      include JIJI::AgentUtil

      # ファイルの一覧を取得する
      def list_files( path )
        check_path path
        @dao.list( path )
      end

      # ファイルの内容を取得する
      def get_file( path )
        check_path path
        @dao.get( path )
      end


      # エージェントの一覧を取得する
      def list_agent_class
        @agent_registry.inject([]) {|list,name|
          next unless name =~ /([^@]+)@([^@]+)/
          list << {
            :class_name=>$1,
            :file_name=>$2,
            :properties=>@agent_registry.get_property_infos(name),
            :description=>@agent_registry.get_description(name)
          }
          list
        }
      end

      # ファイルを追加/更新する
      def put_file( path, body )
        check_path path
        @dao.put( path, body )
        @agent_registry.load( path )
        :success
      end

      # ファイルを追加する
      def add_file( path, body )
        check_path path
        @dao.add( path, body )
        @agent_registry.load( path )
        :success
      end

      # ファイルを削除する
      def remove( paths )
        result = {:success=>{},:failed=>{}}
        targets = {}
        paths.each {|path|
          begin
            check_path path
            # agents, sharedは削除できない
            if path =~ /^(#{@agent_dir}|#{@shared_lib_dir})$/
              raise JIJI::UserError.new( ERROR_ILLEGAL_NAME, "illegal path. path=#{path}" )
            end
            targets[path] =  @dao.directory?(path) \
              ? targets[path] = @dao.list( path, true ).map{|item| item[:path]} \
              : [path]
          rescue Exception
            result[:failed][path] = mk_error_info(path,$!)
          end
        }
        targets.each_pair {|path, files|
          begin
            @dao.delete( path )
            result[:success][path] = {:path=>path}
          rescue Exception
            result[:failed][path] = mk_error_info(path,$!)
            next
          end
          begin
            files.each {|f|
              @agent_registry.unload(f)
            }
          rescue Exception
            #ロードで発生したエラーはログ出力のみして握る
            server_logger.error $!
          end
        }
        result
      end

      # ファイルを移動する
      def move( files, to  )
        check_path to
        result = {:success=>{},:failed=>{}}
        targets = {}
        files.each {|path|
          begin
            check_path path
            targets[path] =  @dao.directory?(path) \
              ? targets[path] = @dao.list( path, true ).map{|item| item[:path]} \
              : [path]
          rescue Exception
            result[:failed][path] = mk_error_info(path,$!)
          end
        }
        targets.each_pair {|path,files|
          begin
            @dao.move( from, to )
            result[:success][path] = {:path=>path}
          rescue Exception
            result[:failed][path] = mk_error_info(path,$!)
            next
          end
          begin
            files.each {|f|
              @agent_registry.unload(f)
            }
            @dao.list( "#{to}/#{File.basename(from)}", true ) {|f|
              @agent_registry.load(f)
            }
          rescue Exception
            #ロードで発生したエラーはログ出力のみして握る
            server_logger.error $!
          end
        }
        result
      end


      # ファイルを移動する
      def rename( path, new_name )
        check_path path
        # agents, sharedはリネームできない
        if path =~ /^(#{@agent_dir}|#{@shared_lib_dir})$/
          raise JIJI::UserError.new( ERROR_ILLEGAL_NAME, "illegal path. path=#{path}" )
        end
        new_path = "#{File.dirname(path)}/#{new_name}"
        files = @dao.directory?(path) ? @dao.list( path, true ).reject{|item| 
          item[:type] == :directory 
        }.map {|item|
          item[:path]
        } : [path]
        @dao.rename( path, new_path )
        begin
          files.each {|f|
            server_logger.info f
            @agent_registry.unload(f)
            @agent_registry.load( f.sub( path, new_path ))
          }
        rescue Exception
          #ロードで発生したエラーはログ出力のみして握る
          server_logger.error $!
        end
        :success
      end

      # フォルダを作成する
      def mkcol( path  )
        check_path path
        @dao.mkcol( path )
        :success
      end

      # プロセスに登録されているエージェントの一覧を得る
      def list_agent( process_id )
        p = process_manager.get( process_id )
        safe(4) {
          p.agent_manager.collect.map! {|entry|
            props = entry[1].agent.properties
            {
              :name=>entry[0],
              :properties=>entry[1].agent.property_infos.map! {|info|
                prop = props.find() {|e| e[0] == info.id.to_s }
                { :id=>info.id.to_s, :info=>info, :value=> prop ? prop[1] : nil }
              },
              :description=>entry[1].agent.description,
              :active=>entry[1].active
            }
          }
        }
      end

      # プロセスのエージェントを一時的に無効化する
      def off( process_id, name )
        p = process_manager.get( process_id )
        p.agent_manager.off( name )
        :success
      end
      # プロセスのエージェントの無効化を解除する
      def on( process_id, name )
        p = process_manager.get( process_id )
        p.agent_manager.on( name )
        :success
      end
      # プロセスのエージェントの無効化状態を取得する
      def on?( process_id, name )
        p = process_manager.get( process_id )
        p.agent_manager.on?( name )
      end
      attr :agent_registry, true
      attr :process_manager, true
      attr :agent_dir, true
      attr :shared_lib_dir, true
      attr :dao, true
      attr :server_logger, true
    private
      def check_path(path)
        unless path =~ /^(#{@agent_dir}|#{@shared_lib_dir})(\/.*)?/
          raise JIJI::UserError.new( ERROR_ILLEGAL_NAME, "illegal path. path=#{path}" )
        end
      end

      def mk_error_info( path, error )
        return {
          :path=>path,
          :code=>error.respond_to?(:code) ? error.code : "",
          :msg=>error.to_s
        }
      end

    end

  end
end