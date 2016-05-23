module CephRuby
  # An Object in Ceph
  class RadosObject
    attr_accessor :pool, :name

    def initialize(pool, name)
      self.pool = pool
      self.name = name
      yield(self) if block_given?
    end

    def exists?
      log('exists?')
      !stat.nil?
    rescue SystemCallError => e
      return false if e.errno == Errno::ENOENT::Errno
      raise e
    end

    def overwrite(data)
      size = data.bytesize
      log("overwrite size #{size}")
      ret = Lib::Rados.rados_write_full(pool.handle, name, data, size)
      raise SystemCallError.new("overwrite of #{size} bytes to '#{name}'"\
                                ' failed', -ret) if ret < 0
    end

    def write(offset, data)
      size = data.bytesize
      log("write offset #{offset}, size #{size}")
      ret = Lib::Rados.rados_write(pool.handle, name, data, size, offset)
      raise SystemCallError.new("write of #{size} bytes to '#{name}'"\
                                " at #{offset} failed", -ret) if ret < 0
    end

    def append(data)
      size = data.bytesize
      log("append #{size}B")
      ret = Lib::Rados.rados_append(pool.handle, name, data, size)
      raise SystemCallError.new("appendment of #{size} bytes to '#{name}'"\
                                ' failed', -ret) if ret < 0
    end

    alias exist? exists?

    def read(offset, size)
      log("read offset #{offset}, size #{size}")
      data_p = FFI::MemoryPointer.new(:char, size)
      ret = Lib::Rados.rados_read(pool.handle, name, data_p, size, offset)
      raise SystemCallError.new("read of #{size} bytes from '#{name}'"\
                                " at #{offset} failed", -ret) if ret < 0
      data_p.get_bytes(0, ret)
    end

    def read_full
      log('read_full')
      read 0, size
    end

    def destroy
      log('destroy')
      ret = Lib::Rados.rados_remove(pool.handle, name)
      raise SystemCallError.new("destroy of '#{name}' failed", -ret) if ret < 0
    end

    def resize(size)
      log("resize size #{size}")
      ret = Lib::Rados.rados_trunc(pool.handle, name, size)
      raise SystemCallError.new("resize of '#{name}'"\
                                " to #{size} failed", -ret) if ret < 0
    end

    def stat
      log('stat')
      size_p = FFI::MemoryPointer.new(:uint64)
      mtime_p = FFI::MemoryPointer.new(:uint64)
      ret = Lib::Rados.rados_stat(pool.handle, name, size_p, mtime_p)
      raise SystemCallError.new("stat of '#{name}' failed", -ret) if ret < 0
      RadosObject.stat_hash(size_p, mtime_p)
    end

    class << self
      def stat_hash(size_p, mtime_p)
        {
          size: size_p.get_uint64(0),
          mtime: Time.at(mtime_p.get_uint64(0))
        }
      end
    end

    def size
      stat[:size]
    end

    def mtime
      stat[:mtime]
    end

    def xattr(name = nil)
      Xattr.new(self, name)
    end

    def xattr_enumerator
      ::CephRuby::XattrEnumerator.new(self)
    end

    def <=>(other)
      pool_check = pool <=> other.pool
      return pool_check unless pool_check == 0
      other.name <=> name
    end

    def eql?(other)
      return false unless other.class == self.class
      self == other
    end

    # helper methods below

    def log(message)
      CephRuby.log("rados object #{pool.name}/#{name} #{message}")
    end
  end
end
