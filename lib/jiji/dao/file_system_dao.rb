
require 'fileutils'
require 'jiji/error'

module JIJI
  module Dao

    #ファイルシステムにデータを保存するDAO
    class FileSystemDao

      #コンストラクタ
      #base:: 保存先の基点となるディレクトリ
      def initialize( base )
        @base = base
      end

      #パスが示すファイルのデータを取得する。
      def get( path )
        path = validate_path( path, :exist, :is_file )
        return FileLock.new(path).readlock {|f|
          f.read
        }
      end

      #パスが示すフォルダ配下の一覧を取得する。
      def list( path="", recursive=false )
        path = validate_path( path, :exist, :is_directory )
        Dir.glob( "#{path}/#{recursive ? '**/*' : '*' }" ).map {|item|
          next if File.basename(item) =~ /^\..*/
          { :path  =>item.sub( /^#{@base}\//, "" ),
            :name  =>File.basename(item),
            :update=>File.mtime(item).to_i,
            :type  =>File.directory?(item) ? :directory : :file}
        }.sort_by {|item| "#{item[:type]}/#{item[:path]}" }
      end

      #ファイルを追加する。
      def add( path, body )
        validate_path( path, :exist_parent, :not_exist )
        put( path, body )
        :success
      end

      #ファイルを追加/更新する。
      def put( path, body )
        path = validate_path( path, :exist_parent, :is_file )
        FileLock.new(path).writelock {|f|
          f << body
        }
        :success
      end

      #ファイルまたはディレクトリを破棄する
      def delete( path )
        path = validate_path( path, :exist )
        if ( File.file? path )
          FileLock.new(path).writelock {|f|
            FileUtils.rm_rf path
          }
        else
          FileUtils.rm_rf path
        end
        :success
      end


      #ファイル/フォルダを移動する
      def move( from, to )
        from = validate_path( from, :exist )
        to = validate_path( to, :exist, :is_directory )
        FileUtils.mv from, to
        :success
      end

      #ファイル/フォルダをリネームする
      def rename( from, to )
        from = validate_path( from, :exist )
        to = validate_path( to, :not_exist )
        FileUtils.mv from, to
        :success
      end

      #ファイル/フォルダをコピーする
      def copy( from, to )
        from = validate_path( from, :exist )
        to = validate_path( to )
        FileUtils.cp_r from, to
        :success
      end

      #フォルダを作成する
      def mkcol(path)
        path = validate_path( path, :exist_parent, :not_exist )
        FileUtils.mkdir_p path
        :success
      end

      #ディレクトリかどうか評価する。
      def directory?(path)
        path = validate_path( path, :exist )
        File.directory?(path)
      end

      #データ保存先の基点となるディレクトリ
      attr_reader :base

    private
      #パスを正規化する
      #steps:: パスを示す文字列
      #return:: 正規化されたパス(baseからの絶対パス)
      def validate_path( path, *options )
        # パスの文字列をチェック。
        steps = path.split( /\/+/ ).map{|str| str.strip }
        steps.each {|step|
          if !step || step.length <= 0 || step.strip.length <= 0
            raise JIJI::UserError.new( JIJI::ERROR_ILLEGAL_NAME, "illegal file or directory name. name=#{step}" )
          end
          unless step =~ VALID_FILE_NAME
            raise JIJI::UserError.new( JIJI::ERROR_ILLEGAL_NAME, "illegal file or directory name. name=#{step}" )
          end
          if step =~ /^\.+$/
            raise JIJI::UserError.new( JIJI::ERROR_ILLEGAL_NAME, "illegal file or directory name. name=#{step}" )
          end
          if step =~ /^\..*/
            raise JIJI::UserError.new( JIJI::ERROR_ILLEGAL_NAME, "illegal file or directory name. name=#{step}" )
          end
        }
        #ファイルパス構築
        file = "#{@base}#{ steps.empty? ? "" : "/" + steps.join( "/" )}"
        parent = File.dirname( file )

        #オプションのチェック
        op = options.inject({}){|h,o| h[o] = true; h }
        if op.key?(:is_directory) && File.exist?( file )
          unless File.directory?( file )
            raise JIJI::UserError.new( JIJI::ERROR_IS_NOT_FOLDER, "target is not a folder. path=#{file}" )
          end
        end
        if op.key?(:is_file) && File.exist?( file )
          unless File.file?( file )
            raise JIJI::UserError.new( JIJI::ERROR_IS_NOT_FILE, "target is not a file. path=#{file}" )
          end
        end
        if op.key?(:exist) && !File.exist?( file )
          raise JIJI::UserError.new( JIJI::ERROR_NOT_FOUND, "file or directory is not found. path=#{file}" )
        end
         if op.key?(:not_exist) && File.exist?( file )
          raise JIJI::UserError.new( JIJI::ERROR_ALREADY_EXIST, "file or directory is already exist. path=#{file}" )
        end
        if op.key?(:exist_parent) && !( File.exist?( parent ) && File.directory?( parent ))
          raise JIJI::UserError.new( JIJI::ERROR_NOT_FOUND, "directory is not found. directory=#{parent}" )
        end
        return file
      end
      VALID_FILE_NAME = /^[A-Za-z0-9_\+\-\#\'\!\~\(\)\[\]\.\{\}]+$/
    end
  end
end