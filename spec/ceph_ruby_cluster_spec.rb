require 'spec_helper'
describe CephRuby::Cluster do
  let(:config) { cluster_config }
  let(:cluster) { ::CephRuby::Cluster.new(config) }
  subject { cluster }

  describe 'should respond to' do
    it 'shutdown' do
      expect(subject).to respond_to :shutdown
    end

    it 'connect' do
      expect(subject).to respond_to :connect
    end

    it 'setup_using_file' do
      expect(subject).to respond_to :setup_using_file
    end

    it 'log' do
      expect(subject).to respond_to :log
    end

    it 'pool' do
      expect(subject).to respond_to :pool
    end

    it 'pools' do
      expect(subject).to respond_to :pools
    end

    it 'pool_id_by_name' do
      expect(subject).to respond_to :pool_id_by_name
    end

    it 'pool_name_by_id' do
      expect(subject).to respond_to :pool_name_by_id
    end

    it 'status' do
      expect(subject).to respond_to :status
    end

    it 'fsid' do
      expect(subject).to respond_to :fsid
    end
  end

  describe 'fsid' do
    subject { cluster.fsid }
    it 'should return a 36 byte string' do
      expect(subject.length).to be 36
    end
  end

  describe 'status' do
    subject { cluster.status }
    it 'should return a hash' do
      expect(subject).to be_a Hash
    end

    it 'should have the correct keys' do
      expect(subject.key?(:kb)).to be true
      expect(subject.key?(:kb_used)).to be true
      expect(subject.key?(:kb_avail)).to be true
      expect(subject.key?(:num_objects)).to be true
    end
  end

  # Starter pool functionality, check the cluster methods exist
  describe 'pool functions' do
    describe 'pool method' do
      it 'should return a pool object' do
        expect(subject.pool(config[:pool][:name])).to be_a ::CephRuby::Pool
      end

      describe 'when passed a block' do
        it 'should pass a pool into the block' do
          obj = nil
          subject.pool(config[:pool][:name]) { |p| obj = p }
          expect(obj).to be_a ::CephRuby::Pool
        end
      end
    end

    describe 'pools method' do
      it 'should return a PoolEnumerator' do
        expect(subject.pools).to be_a ::CephRuby::PoolEnumerator
      end

      describe 'when passed a block into each', require_cluster_read: true do
        it 'should pass as many pools into the block as there are' do
          subject.pools.each do |p|
            # This won't prove anything unless there are some pools
            expect(p).to be_a ::CephRuby::Pool
          end
        end
      end
    end
  end
end
