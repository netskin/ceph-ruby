module CephRuby
  # Pool Helper MEthods
  module PoolHelper
    def by_id(cluster, id, &block)
      Pool.new(cluster, cluster.pool_name_by_id(id), &block)
    end

    def create_with_all(auid, rule_id)
      ret = Lib::Rados.rados_pool_create_with_all(cluster.handle, name,
                                                  auid, rule_id)
      raise SystemCallError.new("create pool with auid: #{auid}, "\
                                "rule_id: #{rule_id} failed", -ret) if ret < 0
    end

    def create_with_rule(rule_id)
      ret = Lib::Rados.rados_pool_create_with_crush_rule(cluster.handle, name,
                                                         rule_id)
      raise SystemCallError.new("create pool with rule_id: #{rule_id}"\
                                ' failed', -ret) if ret < 0
    end

    def open?
      !handle.nil?
    end

    def ensure_open
      return if open?
      open
    end

    def log(message)
      CephRuby.log("pool #{name} #{message}")
    end

    def <=>(other)
      cluster_check = other.cluster <=> cluster
      return cluster_check unless cluster_check == 0
      other.name <=> name
    end

    def eql?(other)
      return false unless other.class == self.class
      self == other
    end
  end
end
