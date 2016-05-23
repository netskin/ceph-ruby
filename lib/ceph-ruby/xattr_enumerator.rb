module CephRuby
  # Enumerator for Ceph Rados Objects Xattr
  class XattrEnumerator
    include Enumerable

    attr_accessor :object, :pool
    attr_reader :handle

    def initialize(object)
      self.object = object
      self.pool = object.pool
      open
    end

    def close
      Lib::Rados.rados_getxattrs_end(handle)
      @handle = nil
    end

    def open?
      !handle.nil?
    end

    def open
      return if open?
      pool.ensure_open
      handle_p = FFI::MemoryPointer.new(:pointer)
      ret = Lib::Rados.rados_getxattrs(pool.handle, object.name, handle_p)
      raise SystemCallError.new('unable to open xattr list', -ret) if ret < 0
      @handle = handle_p.get_pointer(0)
    end

    def each
      return enum_for(:each) unless block_given?
      open
      loop do
        obj = next_xattr_object
        break if obj.nil?
        yield obj
      end
      close
    end

    private

    def next_xattr_object
      key_buffer = FFI::MemoryPointer.new(:pointer, 1)
      val_buffer = FFI::MemoryPointer.new(:pointer, 1)
      size_t_buffer = FFI::MemoryPointer.new(:size_t)
      ret = Lib::Rados.rados_getxattrs_next(handle, key_buffer,
                                            val_buffer, size_t_buffer)
      raise SystemCallError.new('unable to fetch next object', -ret) if ret < 0
      next_xattr(key_buffer)
    end

    def next_xattr(key_buffer)
      str_ptr = key_buffer.read_pointer
      return if str_ptr.null?
      Xattr.new(object, str_ptr.read_string)
    end
  end
end
