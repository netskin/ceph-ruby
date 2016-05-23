require 'spec_helper'

describe CephRuby::Xattr do
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

  describe 'for a Named Rados Object' do
    let(:rados_object) { pool.rados_object(object_name) }
    let(:rados_object_content) do
      'subject content subject content '\
      'subject content subject content '\
      'subject content subject content '\
      'subject content subject content'
    end

    subject { rados_object }
    let(:xattribute_key) { 'testxattr_key' }
    let(:xattribute_val) { 'testxattr_value' }
    let(:xattribute_large_val) { 'abcdefghijklmnopqrstuvwxyz0123456789~!@#$^' }
    it 'Should be a ::CephRuby::RadosObject object' do
      expect(subject).to be_a ::CephRuby::RadosObject
    end

    describe 'during object creation' do
      it 'should be writable' do
        expect { subject.write(0, rados_object_content) }.not_to raise_exception
      end
    end

    describe 'after object creation' do
      subject { rados_object.xattr_enumerator }

      describe 'methods' do
        it 'should respond to each' do
          expect(subject).to respond_to :each
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
      end

      describe 'with no xattr associated' do
        it 'should have no entries' do
          expect(subject.inject(0) { |a, _e| a + 1 }).to be 0
        end
      end

      describe 'after xattr added' do
        before { rados_object.xattr(xattribute_key).value = xattribute_val }

        it 'should yield Xattr objects' do
          expect(subject.first).to be_a ::CephRuby::Xattr
        end

        it 'should have the xattr in the list' do
          expect(subject.any? { |x| x.name == xattribute_key }).to be true
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
