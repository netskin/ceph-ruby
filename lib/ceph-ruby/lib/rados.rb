require 'ffi'

# see https://github.com/ceph/ceph/blob/v0.48.2argonaut/src/pybind/rados.py

module CephRuby
  module Lib
    # Ruby bindings for librados
    module Rados
      extend FFI::Library

      ffi_lib ['rados', 'librados.so.2']

      attach_function 'rados_version', [:pointer, :pointer, :pointer], :void

      attach_function 'rados_create', [:pointer, :string], :int

      attach_function 'rados_create2', [:pointer, :string, :string,
                                        :uint64], :int

      attach_function 'rados_connect', [:pointer], :int

      attach_function 'rados_conf_read_file', [:pointer, :string], :int

      attach_function 'rados_shutdown', [:pointer], :void

      attach_function 'rados_cluster_stat', [:pointer, :pointer], :int

      attach_function 'rados_cluster_fsid', [:pointer, :buffer_out,
                                             :size_t], :int

      attach_function 'rados_pool_list', [:pointer, :buffer_out, :size_t], :int

      attach_function 'rados_pool_lookup', [:pointer, :string], :int

      attach_function 'rados_pool_reverse_lookup', [:pointer, :int,
                                                    :buffer_out, :size_t], :int

      attach_function 'rados_pool_create', [:pointer, :string], :int

      attach_function 'rados_pool_create_with_auid', [:pointer, :string,
                                                      :uint64], :int

      attach_function 'rados_pool_create_with_crush_rule', [:pointer, :string,
                                                            :uint8], :int

      attach_function 'rados_pool_create_with_all', [:pointer, :string,
                                                     :uint64, :uint8], :int

      attach_function 'rados_pool_delete', [:pointer, :string], :int

      attach_function 'rados_ioctx_pool_set_auid', [:pointer, :uint64], :int

      attach_function 'rados_ioctx_pool_get_auid', [:pointer, :pointer], :int

      attach_function 'rados_ioctx_pool_stat', [:pointer, :pointer], :int

      attach_function 'rados_ioctx_get_id', [:pointer], :int

      attach_function 'rados_ioctx_get_pool_name', [:pointer, :buffer_out,
                                                    :size_t], :int

      attach_function 'rados_ioctx_set_namespace', [:pointer, :string], :void

      attach_function 'rados_ioctx_create', [:pointer, :string, :pointer], :int

      attach_function 'rados_ioctx_destroy', [:pointer], :void

      attach_function 'rados_write', [:pointer, :string, :buffer_in,
                                      :size_t, :off_t], :int

      attach_function 'rados_write_full', [:pointer, :string, :buffer_in,
                                           :size_t], :int

      attach_function 'rados_read', [:pointer, :string, :buffer_out,
                                     :size_t, :off_t], :int
      attach_function 'rados_append', [:pointer, :string, :buffer_out,
                                       :size_t], :int
      attach_function 'rados_remove', [:pointer, :string], :int

      attach_function 'rados_trunc', [:pointer, :string, :size_t], :int

      attach_function 'rados_stat', [:pointer, :string, :pointer,
                                     :pointer], :int

      attach_function 'rados_getxattr', [:pointer, :string, :string,
                                         :buffer_out, :size_t], :int
      attach_function 'rados_setxattr', [:pointer, :string, :string,
                                         :buffer_in, :size_t], :int
      attach_function 'rados_rmxattr', [:pointer, :string, :string], :int

      attach_function 'rados_getxattrs', [:pointer, :string, :pointer], :int

      attach_function 'rados_getxattrs_next', [:pointer, :pointer, :pointer,
                                               :pointer], :int
      attach_function 'rados_getxattrs_end', [:pointer], :void

      attach_function 'rados_nobjects_list_open', [:pointer, :pointer], :int

      attach_function 'rados_nobjects_list_seek', [:pointer, :uint32], :uint32

      attach_function 'rados_nobjects_list_next', [:pointer, :pointer,
                                                   :pointer,
                                                   :pointer], :int

      attach_function 'rados_nobjects_list_close', [:pointer], :void

      attach_function 'rados_nobjects_list_get_pg_hash_position',
                      [:pointer], :uint32

      class MonitorStatStruct < FFI::Struct #:nodoc:
        layout :kb, :uint64,
               :kb_used, :uint64,
               :kb_avail, :uint64,
               :num_objects, :uint64
        def to_hash
          return {} if members.empty?
          Hash[* members.collect { |m| [m, self[m]] }.flatten!]
        end
      end

      class PoolStatStruct < FFI::Struct #:nodoc:
        layout :num_bytes, :uint64,
               :num_kb, :uint64,
               :num_objects, :uint64,
               :num_object_clones, :uint64,
               :num_object_copies, :uint64,
               :num_objects_missing_on_primary, :uint64,
               :num_objects_unfound, :uint64,
               :num_objects_degraded, :uint64,
               :num_rd, :uint64,
               :num_rd_kb, :uint64,
               :num_wr, :uint64,
               :num_wr_kb, :uint64

        def to_hash
          return {} if members.empty?
          Hash[* members.collect { |m| [m, self[m]] }.flatten!]
        end
      end

      def self.version
        major = FFI::MemoryPointer.new(:int)
        minor = FFI::MemoryPointer.new(:int)
        extra = FFI::MemoryPointer.new(:int)
        rados_version(major, minor, extra)
        {
          major: major.get_int(0),
          minor: minor.get_int(0),
          extra: extra.get_int(0)
        }
      end

      def self.version_string
        "#{version[:major]}.#{version[:minor]}.#{version[:extra]}"
      end
    end
  end
end
