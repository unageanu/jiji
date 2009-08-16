require "fileutils"
require 'jiji/util/file_lock'
require 'kconv'
require 'yaml'
require 'jiji/util/fix_yaml_bug'

module Cache

  class YAMLCacheInterceptor
    def initialize( range, cache_file_prefix, &block)
      @name = "cache"
      @range = range
      @cache_file_prefix = cache_file_prefix
      @block = block
    end
    def invoke( mi )
      cache_file =  @cache_file_prefix + "_" +  mi.name.to_s
      cache_file += "_" + @block.call(mi.name,*mi.arguments) if @block != nil
      cache_file += ".yaml"

      flock = FileLock.new(cache_file + ".lock")
      current = Time.new

      res = nil
      flock.writelock(){
        # キャッシュがあればキャッシュから読む
        if ( File.exist?(cache_file) && current.to_i < (File.mtime(cache_file).to_i + @range) )
          res = YAML.load_file cache_file
        else
          res =  mi.proceed
          File.open( cache_file, "w" ) { |f|
            f.write( YAML.dump(res) )
          }
          File.utime(current, current, cache_file)
        end
      }
      return res
    end
    attr_reader :name
  end

  class YAMLCache
    def initialize(delegate, range, cache_file_prefix, regex=".*", &block)
      @delegate = delegate
      @range = range
      @cache_file_prefix = cache_file_prefix
      @regex = regex
      @block = block
    end

    def method_missing(name, *args )

      return @delegate.send( name, *args ) if ( !name.to_s.match(@regex) )

      cache_file =  @cache_file_prefix + "_" +  name.to_s
      cache_file += "_" + @block.call(name,*args) if @block != nil

      cache_file += ".yaml"

      flock = FileLock.new(cache_file + ".lock")
      current = Time.new

      res = nil
      flock.writelock(){
        # キャッシュがあればキャッシュから読む
        if ( File.exist?(cache_file) && current.to_i < (File.mtime(cache_file).to_i + @range) )
          res = YAML.load_file cache_file
        elsif
          res =  @delegate.send( name, *args )
          File.open( cache_file, "w" ) { |f|
            f.write( YAML.dump(res) )
          }
          File.utime(current, current, cache_file)
        end
      }
      return res
    end
  end
end