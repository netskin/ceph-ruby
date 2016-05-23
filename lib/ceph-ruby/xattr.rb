module CephRuby
  # Representation of a File extended Attribute
  class Xattr
    attr_accessor :rados_object, :name, :pool

    def initialize(rados_object, name)
      raise Errno::ENOENT, 'RadosObject is nil' unless rados_object.exists?
      raise SystemCallError.new(
        'xattr name cannot be nil',
        Errno::ENOENT::Errno
      ) if name.nil?
      self.rados_object = rados_object
      self.pool = rados_object.pool
      self.name = name
      yield(self) if block_given?
    end

    def value(size = 4096)
      read size
    end

    def value=(value)
      write value
    end

    def destroy
      log('destroy')
      ret = Lib::Rados.rados_rmxattr(pool.handle,
                                     rados_object.name,
                                     name)
      raise SystemCallError.new("destruction of xattr '#{name}' failed",
                                -ret) if ret < 0
    end

    def to_s
      read
    end

    def log(message)
      CephRuby.log('rados obj xattr '\
                   "#{rados_object.name}/#{name} #{message}")
    end

    private

    def read(size)
      log("read #{size}b")
      data_p = FFI::MemoryPointer.new(:char, size)
      ret = Lib::Rados.rados_getxattr(pool.handle,
                                      rados_object.name,
                                      name, data_p, size)
      raise SystemCallError.new("read of xattr '#{name}' failed",
                                -ret) if ret < 0
      data_p.get_bytes(0, ret)
    end

    def write(data)
      size = data.bytesize
      log("write size #{size}")
      ret = Lib::Rados.rados_setxattr(pool.handle,
                                      rados_object.name,
                                      name, data, size)
      raise SystemCallError.new("write of xattr '#{name}' failed",
                                -ret) if ret < 0
    end
  end
end
