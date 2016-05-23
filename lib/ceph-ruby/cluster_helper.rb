module CephRuby
  # Helper Methods for CephRuby::Cluster
  module ClusterHelper
    def setup_handle(options)
      handle_p = FFI::MemoryPointer.new(:pointer)
      ret = Lib::Rados.rados_create2(handle_p,
                                     options[:cluster],
                                     options[:user],
                                     options[:flags])
      raise SystemCallError.new('open of cluster failed', -ret) if ret < 0
      handle_p.get_pointer(0)
    end

    def default_options
      {
        config_path: '/etc/ceph',
        user: 'client.admin',
        cluster: 'ceph'
      }
    end

    def uint?(value)
      value.is_a?(Integer) && value >= 0
    end

    def log(message)
      CephRuby.log("cluster #{message}")
    end

    def <=>(other)
      other.options <=> options
    end

    def eql?(other)
      return false if other.class != self.class
      self == other
    end
  end
end
