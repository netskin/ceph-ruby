module CephRuby
  # Enumerator for Ceph Rados Objects
  class RadosObjectEnumerator
    include Enumerable

    class << self
       attr_accessor :limit
    end

    attr_accessor :pool
    attr_reader :handle, :page

    def initialize(pool)
      self.pool = pool
      @page = 0

      open
    end

    def paginate(page = 0)
      @page = page ||= 0
      to = CephRuby::RadosObjectEnumerator.limit
      to = 0 if to.nil?
      seek page * to
    end

    def seek(to)
      ret = Lib::Rados.rados_nobjects_list_seek(handle, to)
      raise SystemCallError('unable to seek to position', -ret) if ret < 0
      self
    end

    def position
      Lib::Rados.rados_nobjects_list_get_pg_hash_position(handle)
    end

    def close
      Lib::Rados.rados_nobjects_close(handle)
      @handle = nil
    end

    def open?
      !handle.nil?
    end

    def open
      return if open?
      pool.ensure_open
      handle_p = FFI::MemoryPointer.new(:pointer)
      ret = Lib::Rados.rados_nobjects_list_open(pool.handle, handle_p)
      raise SystemCallError('unable to open object list', -ret) if ret < 0
      @handle = handle_p.get_pointer(0)
    end

    def each
      return enum_for(:each) unless block_given?
      while within_limit
        obj = next_rados_object
        return if obj.nil?
        yield obj
      end
    ensure
      paginate(page)
    end

    def within_limit
      return true if CephRuby::RadosObjectEnumerator.limit.nil?
      position < (CephRuby::RadosObjectEnumerator.limit * (page + 1))
    end

    private

    def next_rados_object
      entry_buffer = FFI::MemoryPointer.new(:pointer, 1)
      ret = Lib::Rados.rados_nobjects_list_next(handle, entry_buffer,
                                                nil, nil)
      return unless within_limit
      return if ret == -Errno::ENOENT::Errno
      raise SystemCallError.new('unable to fetch next object', -ret) if ret < 0
      next_object(entry_buffer)
    end

    def next_object(entry_buffer)
      str_ptr = entry_buffer.read_pointer
      return if str_ptr.null?
      RadosObject.new(pool, str_ptr.read_string)
    end
  end
end
