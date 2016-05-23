module CephRuby
  # Represents a Ceph pool
  # = usage
  # pool = cluster.pool('name')
  class Pool
    extend CephRuby::PoolHelper
    include CephRuby::PoolHelper
    include ::Comparable
    attr_accessor :cluster, :name, :handle

    def initialize(cluster, name)
      self.cluster = cluster
      self.name = name
      begin
        yield(self)
      ensure
        close
      end if block_given?
    end

    def exists?
      log('exists?')
      ret = Lib::Rados.rados_pool_lookup(cluster.handle, name)
      return true if ret >= 0
      return false if ret == -Errno::ENOENT::Errno
      raise SystemCallError.new("lookup of '#{name}' failed", -ret) if ret < 0
    end

    alias exist? exists?

    def id
      ensure_open
      Lib::Rados.rados_ioctx_get_id(handle)
    end

    def auid=(dst_auid)
      log("auid=#{dst_auid}")
      ensure_open
      ret = Lib::Rados.rados_ioctx_pool_set_auid(handle, dst_auid)
      raise SystemCallError.new('set of auid for'\
                                 " '#{name}' failed", -ret) if ret < 0
    end

    def auid
      log('auid')
      ensure_open
      auid_p = FFI::MemoryPointer.new(:uint64)
      ret = Lib::Rados.rados_ioctx_pool_get_auid(handle, auid_p)
      raise SystemCallError.new('get of auid for'\
                                " '#{name}' failed", -ret) if ret < 0
      auid_p.get_uint64(0)
    end

    def open
      return if open?
      log('open')
      handle_p = FFI::MemoryPointer.new(:pointer)
      ret = Lib::Rados.rados_ioctx_create(cluster.handle, name, handle_p)
      raise SystemCallError.new('creation of io context for'\
                                " '#{name}' failed", -ret) if ret < 0
      self.handle = handle_p.get_pointer(0)
    end

    def close
      return unless open?
      log('close')
      Lib::Rados.rados_ioctx_destroy(handle)
      self.handle = nil
    end

    def rados_object(name, &block)
      ensure_open
      RadosObject.new(self, name, &block)
    end

    def rados_object_enumerator(&block)
      ensure_open
      RadosObjectEnumerator.new(self, &block)
    end

    def rados_block_device(name, &block)
      ensure_open
      RadosBlockDevice.new(self, name, &block)
    end

    def create(auid: nil, rule_id: nil)
      log("create auid: #{auid}, rule: #{rule_id}")
      rule_id ||= 0
      return create_with_all(auid, rule_id) if auid
      create_with_rule(rule_id)
      close
    end

    def destroy
      ret = Lib::Rados.rados_pool_delete(cluster.handle, name)
      raise SystemCallError.new('delete pool failed',
                                -ret) if ret < 0
    end

    def stat
      log('stat')
      stat_s = Lib::Rados::PoolStatStruct.new
      ensure_open
      ret = Lib::Rados.rados_ioctx_pool_stat(handle, stat_s)
      raise SystemCallError.new('stat failed',
                                -ret) if ret < 0
      stat_s.to_hash
    end

    def flush_aio
      ensure_open
      ret = Lib::Rados.rados_aio_flush(handle)
      raise SystemCallError.new('aio flush faield',
                                -ret) if ret < 0
    end
  end
end
