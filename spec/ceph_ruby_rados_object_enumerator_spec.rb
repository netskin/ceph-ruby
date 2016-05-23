require 'spec_helper'

describe CephRuby::RadosObjectEnumerator do
  let(:config) { cluster_config }
  let(:cluster) { ::CephRuby::Cluster.new(config) }
  let(:pool_name) { config[:pool][:name] }
  let(:crush_id) { config[:pool][:rule_id] }
  let(:pool) { cluster.pool(pool_name) }
  let(:object_name) { config[:pool][:object_name] }

  describe 'pool creation', requires_create_delete: true do
    subject { pool }
    it 'should be creatable' do
      expect { pool.create(rule_id: crush_id) }.to_not raise_exception
    end
  end

  describe 'RadosObjectEnumerator' do
    let(:enumerator) { pool.rados_object_enumerator }

    subject { enumerator }

    describe 'instance' do
      it 'should respond to paginate' do
        expect(subject).to respond_to :paginate
      end

      it 'should respond to each' do
        expect(subject).to respond_to :each
      end

      it 'should respond to page' do
        expect(subject).to respond_to :page
      end

      it 'should respond to position' do
        expect(subject).to respond_to :position
      end

      it 'should respond to close' do
        expect(subject).to respond_to :close
      end

      it 'should respond to open' do
        expect(subject).to respond_to :open
      end

      it 'should respond to open?' do
        expect(subject).to respond_to :open?
      end

      it 'should be a CephRuby::RadosObjectEnumerator' do
        expect(subject).to be_a ::CephRuby::RadosObjectEnumerator
      end
    end

    describe 'on new pool' do
      it 'should be empty' do
        expect(subject.inject(0) { |a, _e| a + 1 }).to be 0
      end
    end

    describe 'after adding 10 objects' do
      before do
        10.times do |i|
          pool.rados_object("#{object_name}.#{i}") do |obj|
            obj.overwrite('some random content')
          end
        end

        it 'should now have 10 items in it' do
          expect(subject.inject(0) { |a, _e| a + 1 }).to be 10
        end

        it 'should yield RadosObjects from each' do
          expect(subject.first).to be_a ::CephRuby::RadosObject
        end
      end
    end
  end

  describe 'pool tidyup', requires_create_delete: true do
    subject { pool }
    it 'should be destroyable' do
      expect { pool.destroy }.to_not raise_exception
    end
  end
end
