require 'spec_helper'

describe CephRuby::Pool do
  let(:config)  { cluster_config }
  let(:cluster) { ::CephRuby::Cluster.new(config) }
  let(:name) { config[:pool][:name] }
  let(:pool) { cluster.pool(name) }
  subject { pool }
  before do
    RSpec.configure do |c|
      c.filter_run_excluding(
        requires_create_delete: true
      ) unless config[:pool][:create_delete]
    end
  end

  describe 'Pool Object' do
    it 'Should be a ::CephRuby::Pool object' do
      expect(subject).to be_a ::CephRuby::Pool
    end

    describe 'should respond to' do
      it 'close' do
        expect(subject).to respond_to :close
      end

      it 'rados_object' do
        expect(subject).to respond_to :rados_object
      end

      it 'rados_object_enumerator' do
        expect(subject).to respond_to :rados_object_enumerator
      end

      it 'rados_block_device' do
        expect(subject).to respond_to :rados_block_device
      end

      it 'open?' do
        expect(subject).to respond_to 'open?'
      end

      it 'ensure_open' do
        expect(subject).to respond_to :ensure_open
      end

      it 'create' do
        expect(subject).to respond_to :create
      end

      it 'id' do
        expect(subject).to respond_to :id
      end

      it 'auid=' do
        expect(subject).to respond_to :auid=
      end

      it 'auid' do
        expect(subject).to respond_to :auid
      end

      it 'open' do
        expect(subject).to respond_to :open
      end

      it 'create' do
        expect(subject).to respond_to :create
      end

      it 'destroy' do
        expect(subject).to respond_to :destroy
      end

      it 'stat' do
        expect(subject).to respond_to :stat
      end

      it 'flush_aio' do
        expect(subject).to respond_to :flush_aio
      end
    end

    describe 'before creation', requires_create_delete: true do
      it 'should not exist' do
        expect(subject.exist?).to be false
      end

      it 'should have the same name' do
        expect(subject.name).to equal name
      end

      it 'should not be open' do
        expect(subject.open?).to be false
      end

      it 'destroy should error' do
        expect { subject.destroy }.to raise_exception(Errno::ENOENT)
      end

      it 'should be creatable' do
        expect { subject.create }.not_to raise_exception
      end
    end

    describe 'after creation' do
      it 'should not be creatable' do
        expect { subject.create }.to raise_exception Errno::EEXIST
      end

      describe 'auid' do
        it 'should be an integer' do
          expect(subject.auid).to be_a Integer
        end
      end

      describe 'stat' do
        subject { pool.stat }

        it 'should be a hash' do
          expect(subject).to be_a Hash
        end

        it 'should have the correct keys' do
          expect(subject.key?(:num_bytes)).to be true
          expect(subject.key?(:num_kb)).to be true
          expect(subject.key?(:num_objects)).to be true
          expect(subject.key?(:num_object_clones)).to be true
          expect(subject.key?(:num_object_copies)).to be true
          expect(subject.key?(:num_objects_missing_on_primary)).to be true
          expect(subject.key?(:num_objects_unfound)).to be true
          expect(subject.key?(:num_objects_degraded)).to be true
          expect(subject.key?(:num_rd)).to be true
          expect(subject.key?(:num_wr)).to be true
          expect(subject.key?(:num_wr_kb)).to be true
        end
      end
      describe 'when opened' do
        it 'open? should be true' do
          subject.open
          expect(subject.open?).to be true
        end

        it 'should still be open after ensure_open is called' do
          subject.ensure_open
          expect(subject.open?).to be true
        end

        describe 'when closed' do
          it 'should be closed' do
            subject.close
            expect(subject.open?).to be false
          end

          it 'should be open after ensure_open is called' do
            subject.ensure_open
            expect(subject.open?).to be true
          end
        end
      end

      describe 'when opening a rados_object' do
        it 'should return a RadosObject' do
          expect(
            subject.rados_object('test_object')
          ).to be_a ::CephRuby::RadosObject
        end
      end

      describe 'when destroying the pool', requires_create_delete: true do
        it 'should not be destroyable' do
          expect { subject.destroy }.to_not raise_exception
        end
      end
    end
  end
end
