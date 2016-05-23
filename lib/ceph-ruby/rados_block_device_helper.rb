module CephRuby
  # Rados BlockDevice helper Methods
  module RadosBlockDeviceHelper
    def self.parse_stat(stat)
      Hash[[:size, :obj_size, :num_objs, :order].map { |k| [k, stat[k]] }]
        .tap do |hash|
        hash[:block_name_prefix] = stat[:block_name_prefix].to_ptr.read_string
      end
    end

    def self.close_handle(handle)
      Lib::Rbd.rbd_close(handle)
      true
    end

    def self.parse_dst_pool(dst_pool, pool)
      if dst_pool.is_a? String
        dst_pool = cluster.pool(dst_pool)
      elsif dst_pool.nil?
        dst_pool = pool
      end
      dst_pool.ensure_open
      dst_pool
    end

    def open?
      !handle.nil?
    end

    def ensure_open
      return if open?
      open
    end

    def log(message)
      CephRuby.log("rbd image #{pool.name}/#{name} #{message}")
    end
  end
end
