require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/attribute_accessors'

require 'ffi'

require 'ceph-ruby/lib/rados'
require 'ceph-ruby/lib/rbd'

require 'ceph-ruby/version'
require 'ceph-ruby/cluster_helper'
require 'ceph-ruby/pool_enumerator'
require 'ceph-ruby/cluster'
require 'ceph-ruby/rados_object_enumerator'
require 'ceph-ruby/pool_helper'
require 'ceph-ruby/pool'
require 'ceph-ruby/rados_block_device_helper'
require 'ceph-ruby/rados_block_device'
require 'ceph-ruby/rados_object'
require 'ceph-ruby/xattr'
require 'ceph-ruby/xattr_enumerator'
# Ceph::Ruby
#
# Easy management of Ceph Distributed Storage System
# (rbd, images, rados objects) using ruby.
module CephRuby
  mattr_accessor :logger

  def self.log(message)
    return unless logger
    logger.info("CephRuby: #{message}")
  end
end
