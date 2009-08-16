class Module
  #プロキシモジュールをincludeする。
  def include_proxy( mod )
    include mod
    class << self 
      def const_missing(id)
        self.included_modules.each {|m|
          begin
            return m.const_get(id)
          rescue NameError
          end
        }
        raise NameError.new
      end
    end
  end
end