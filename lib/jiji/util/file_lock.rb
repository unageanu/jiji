require "fileutils"

# File.flockを利用したRead-Write-Lock
class FileLock
  def initialize(lockfile)
    @lockfile = lockfile
  end

  #===読み込みロックする。
  #- ロックされていても他の読み込みユーザーはブロックさない。
  #- 他の書き込みユーザーはブロックされる。
  def readlock ( &block )
    File.open( @lockfile, "r" ) { |f|
      f.flock(File::LOCK_SH)
      begin
        block.call(f)
      ensure
        f.flock(File::LOCK_UN)
      end
    }
  end

  #===書き込みロックする。
  #- ロックされている場合、他の読み込みユーザー/書き込みユーザー共にブロックされる。
  def writelock ( &block )
    File.open( @lockfile, "w" ) { |f|
      f.flock(File::LOCK_EX)
      begin
        block.call(f)
      ensure
        f.flock(File::LOCK_UN)
      end
    }
  end

end

class DirLock
  def initialize(lockdir)
    @lockfile = "#{lockdir}/.lock"
  end

  #===読み込みロックする。
  #- ロックされていても他の読み込みユーザーはブロックさない。
  #- 他の書き込みユーザーはブロックされる。
  def readlock ( &block )
    mkfile
    File.open( @lockfile, "r" ) { |f|
      f.flock(File::LOCK_SH)
      begin
        block.call
      ensure
        f.flock(File::LOCK_UN)
      end
    }
  end

  #===書き込みロックする。
  #- ロックされている場合、他の読み込みユーザー/書き込みユーザー共にブロックされる。
  def writelock ( &block )
    mkfile
    File.open( @lockfile, "w" ) { |f|
      f.flock(File::LOCK_EX)
      begin
        block.call
      ensure
        f.flock(File::LOCK_UN)
      end
    }
  end

private
  def mkfile
    i=0
    while !File.exist?(@lockfile)
      begin
        FileUtils.touch( @lockfile )
        sleep 0.1
      rescue Exception
        i+=1
        raise $! if i >= 5
      end
    end
  end
end

