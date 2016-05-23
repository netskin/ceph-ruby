module CephRuby
  # = Cluster
  #
  # == Synopsis
  # A cluster object will connect to a Ceph monitor to
  # carry out tasks or access objects from ceph
  #
  # == How to connect
  # clusterA = ::CephRuby::Cluster.new
  # clusterB = ::CephRuby::Cluster.new('/path/to/config/dir')
  # clusterC = ::CephRuby::Cluster.new('/path/to/config/dir', options)
  # clusterD = ::CephRuby::Cluster.new(options)
  # === Options (with defaults)
  #    {
  #       config_dir: '/etc/ceph'
  #       cluster: 'ceph',
  #       user: 'client.admin',
  #       flags: 0
  #    }
  class Cluster
    extend CephRuby::ClusterHelper
    include CephRuby::ClusterHelper
    include ::Comparable
    attr_reader :options
    attr_accessor :handle

    def initialize(config = {}, opts = {})
      setup(config, opts)

      connect

      if block_given?
        begin
          yield(self)
        ensure
          shutdown
        end
      end
    end

    def shutdown
      return unless handle
      log('shutdown')
      Lib::Rados.rados_shutdown(handle)
      self.handle = nil
    end

    def pool(name, &block)
      Pool.new(self, name, &block)
    end

    def pools
      PoolEnumerator.new(self)
    end

    def pool_name_by_id(id, size = 512)
      data_p = FFI::MemoryPointer.new(:char, size)
      ret = Lib::Rados.rados_pool_reverse_lookup(handle,
                                                 id,
                                                 name,
                                                 size)
      raise Errno::ERANGE,
            'buffer size too small' if ret == -Errno::ERANGE::Errno
      raise SystemCallError.new('read of pool name failed', -ret) if ret < 0
      data_p.get_bytes(0, ret)
    end

    def pool_id_by_name(name)
      ret = Lib::Rados.rados_pool_lookup(handle, name)
      raise Errno::ENOENT if ret == -Errno::ERANGE::Errno
      raise SystemCallError.new('read of pool id failed', -ret) if ret < 0
      ret
    end

    def connect
      log('connect')
      ret = Lib::Rados.rados_connect(handle)
      raise SystemCallError.new('connect to cluster failed', -ret) if ret < 0
    end

    def setup_using_file
      log("setup_using_file #{options[:path]}")
      ret = Lib::Rados.rados_conf_read_file(handle, options[:path])
      raise SystemCallError.new('setup of cluster from config file'\
                                " '#{options[:path]}' failed", -ret) if ret < 0
    end

    def status
      log('stat')
      stat_s = Lib::Rados::MonitorStatStruct.new
      ret = Lib::Rados.rados_cluster_stat(handle, stat_s)
      raise SystemCallError.new('retrieve cluster status failed',
                                -ret) if ret < 0
      stat_s.to_hash
    end

    def fsid
      log('fsid')
      data_p = FFI::MemoryPointer.new(:char, 37)
      ret = Lib::Rados.rados_cluster_fsid(handle, data_p, 37)
      raise SystemCallError.new('cluster fsid failed',
                                -ret) if ret < 0
      data_p.get_bytes(0, ret)
    end

    private

    def setup(config, opts)
      log("init lib rados #{Lib::Rados.version_string},"\
          " lib rbd #{Lib::Rbd.version_string}")
      setup_options(config, opts)
      self.handle = Cluster.setup_handle(options)
      setup_using_file
    end

    def setup_options(config, opts)
      @options = Cluster.default_options
      if config.is_a?(::Hash)
        @options.merge! config
      else
        @options.merge! opts
        @options[:config_path] = config
      end

      @options[:flags] = 0 unless Cluster.uint?(@options[:flags])
      @options.freeze
    end
  end
end
