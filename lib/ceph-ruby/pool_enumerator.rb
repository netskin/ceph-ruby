module CephRuby
  # Enumerator of Ceph pools
  class PoolEnumerator
    include Enumerable
    attr_accessor :cluster, :members
    def initialize(cluster)
      self.cluster = cluster
      yield self if block_given?
    end

    def each
      return enum_for(:each) unless block_given?

      pools.each do |pool|
        yield Pool.new(cluster, pool)
      end
    end

    def size
      pools.size
    end

    private

    def pools(size = 512)
      data_p = FFI::MemoryPointer.new(:char, size)
      ret = Lib::Rados.rados_pool_list(cluster.handle, data_p, size)
      return pools(ret) if ret > size
      data_p.get_bytes(0, ret).split("\0")
    end
  end
end
