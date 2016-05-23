require 'spec_helper'

describe CephRuby::Pool do
  let(:config) { cluster_config }
  let(:spconfig) { spec_config }
  let(:cluster) { ::CephRuby::Cluster.new(config) }
  let(:name) { spconfig[:pool][:name] }
  let(:pool_enumerator) { cluster.pools }
  subject { pool_enumerator }
  before do
    RSpec.configure do |c|
      c.filter_run_excluding(
        requires_create_delete: true
      ) unless spconfig[:pool][:create_delete]
      c.filter_run_excluding(
        requires_create_delete: false
      ) if spconfig[:pool][:create_delete]
    end
  end

  describe 'PoolEnumerator Object' do
    it 'Should be a ::CephRuby::PoolEnumerator object' do
      expect(subject).to be_a ::CephRuby::PoolEnumerator
    end

    it 'should respond to each' do
      expect(subject).to respond_to :each
    end

    it 'should respond to size' do
      expect(subject).to respond_to :size
    end

    describe 'without the test pool created', requires_create_delete: true do
      it 'should not include the test pool' do
        expect(subject.include?(cluster.pool(name))).to be false
      end

      describe 'with the test pool created', requires_create_delete: true do
        before { cluster.pool(name, &:create) }
        after { cluster.pool(name, &:destroy) }
        subject { cluster.pools }
        it 'should include the test pool' do
          expect(subject.include?(cluster.pool(name))).to be true
        end
      end
    end

    describe 'when already created', requires_create_delete: false do
      it 'should include the test pool' do
        expect(subject.include?(cluster.pool(name))).to be true
      end
    end
  end
end
