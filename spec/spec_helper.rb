require 'ceph-ruby'
require 'yaml'

def cluster_config
  YAML.load(File.read('.cluster.yml')) if File.exist? '.cluster.yml'
end

def spec_config
  YAML.load(File.read('.cluster.yml')) if File.exist? '.cluster.yml'
end
RSpec.configure do |c|
  config = cluster_config
  c.fail_fast = true
  c.filter_run_excluding(
    requires_cluster_readable: true
  ) unless config[:readable]
  c.filter_run_excluding(
    requires_create_delete: true
  ) unless config[:pool][:create_delete]
  c.filter_run_excluding(
    requires_create_delete: false
  ) if config[:pool][:create_delete]
end
