module CephRuby
  # Rados Block Device
  class RadosBlockDevice
    extend CephRuby::RadosBlockDeviceHelper
    attr_accessor :pool, :name, :handle

    delegate :cluster, to: :pool

    def initialize(pool, name)
      self.pool = pool
      self.name = name
      if block_given?
        begin
          yield(self)
        ensure
          close
        end
      end
    end

    def exists?
      log('exists?')
      RadosBlockDevice.close_handle(open_handle)
    rescue SystemCallError => e
      return false if e.errno == -Errno::ENOENT::Errno
      raise
    end

    def create(size, features = 0, order = 26)
      log("create size #{size}, features #{features}, order #{order}")
      order_p = FFI::MemoryPointer.new(:int)
      order_p.put_int(0, order)
      ret = Lib::Rbd.rbd_create2(pool.handle, name, size, features, order_p)
      raise SystemCallError.new("creation of '#{name}' failed", -ret) if ret < 0
    end

    def open
      return if open?
      log('open')
      self.handle = open_handle
    end

    def open_handle
      handle_p = FFI::MemoryPointer.new(:pointer)
      ret = Lib::Rbd.rbd_open(pool.handle, name, handle_p, nil)
      raise SystemCallError.new("open of '#{name}' failed", -ret) if ret < 0
      handle_p.get_pointer(0)
    end

    def close
      return unless open?
      log('close')
      RadosBlockDevice.close_handle(handle)
      self.handle = nil
    end

    def destroy
      close if open?
      log('destroy')
      ret = Lib::Rbd.rbd_remove(pool.handle, name)
      raise SystemCallError.new("destroy of '#{name}' failed", -ret) if ret < 0
    end

    def write(offset, data)
      ensure_open
      size = data.bytesize
      log("write offset #{offset}, size #{size}")
      ret = Lib::Rbd.rbd_write(handle, offset, size, data)
      raise SystemCallError.new("write of #{size} bytes to '#{name}' "\
                                "at #{offset} failed", -ret) if ret < 0
      raise Errno::EIO, "wrote only #{ret} of #{size} bytes to "\
                           "'#{name}' at #{offset}" if ret < size
    end

    def read(offset, size)
      ensure_open
      log("read offset #{offset}, size #{size}")
      data_p = FFI::MemoryPointer.new(:char, size)
      ret = Lib::Rbd.rbd_read(handle, offset, size, data_p)
      raise SystemCallError.new("read of #{size} bytes from "\
                                "'#{name}' at #{offset} failed",
                                -ret) if ret < 0
      data_p.get_bytes(0, ret)
    end

    def stat
      ensure_open
      log('stat')
      stat = Lib::Rbd::StatStruct.new
      ret = Lib::Rbd.rbd_stat(handle, stat, stat.size)
      raise SystemCallError.new("stat of '#{name}' failed", -ret) if ret < 0
      RadosBlockDevice.parse_stat(stat)
    end

    def resize(size)
      ensure_open
      log("resize size #{size}")
      ret = Lib::Rbd.rbd_resize(handle, size)
      raise SystemCallError.new("resize of '#{name}' to #{size} failed",
                                -ret) if ret < 0
    end

    def size
      stat[:size]
    end

    def copy_to(dst_name, dst_pool = nil)
      ensure_open
      dst_pool = parse_dst(dst, pool)
      dst_pool_name = dst_pool.name
      log("copy_to #{dst_pool_name}/#{dst_name}")
      ret = Lib::Rbd.rbd_copy(handle, dst_pool.handle, dst_name)
      raise SystemCallError.new("copy of '#{name}' to "\
                                "'#{dst_pool_name}/#{dst_name}' failed",
                                -ret) if ret < 0
    end
  end
end
