
require 'csv'

# 追記をサポートするように改造。
class << CSV
  alias_method( :open_org, :open )
  
  def open( path, mode, fs=nil, rs=nil, &block )
    if mode == "a" || mode == "ab"
      open_writer( path, mode, fs, rs, &block)
    else
      open_org( path, mode, fs=nil, rs=nil, &block )
    end
  end
end