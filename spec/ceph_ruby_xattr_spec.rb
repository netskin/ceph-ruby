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

    describe 'before object creation' do
      it 'should not exist' do
        expect(subject.exist?).to be false
      end

      describe 'Xattr' do
        subject { rados_object.xattr(xattribute_key) }

        it 'should raise an exception if added to a nil rados object' do
          expect { subject }.to raise_exception Errno::ENOENT
        end
      end
    end

    describe 'during object creation' do
      it 'should be writable' do
        expect { subject.write(0, rados_object_content) }.not_to raise_exception
      end
    end

    describe 'after object creation' do
      subject { rados_object.xattr(xattribute_key) }

      describe 'methods' do
        it 'should respond to value' do
          expect(subject).to respond_to :value
        end

        it 'should respond to value=' do
          expect(subject).to respond_to :value
        end

        it 'should respond to destroy' do
          expect(subject).to respond_to :destroy
        end
      end

      describe 'calling value on an empty xattr' do
        it 'should throw an exception' do
          expect { subject.value }.to raise_exception(Errno::ENODATA)
        end
      end

      describe 'calling value=' do
        it 'should not throw an exception' do
          expect { subject.value = xattribute_val }.not_to raise_exception
        end

        describe 'then calling value' do
          it 'should return the value' do
            expect(subject.value).to eq(xattribute_val)
          end
        end
      end

      describe 'calling value= with larger value' do
        it 'should not throw an exception' do
          expect { subject.value = xattribute_large_val }.not_to raise_exception
        end

        describe 'then calling value' do
          it 'should match the value' do
            expect(subject.value).to eq(xattribute_large_val)
          end
        end
      end

      describe 'calling value= with the original value' do
        it 'should not throw an exception' do
          expect { subject.value = xattribute_val }.not_to raise_exception
        end

        describe 'then calling value' do
          it 'should return the value' do
            expect(subject.value).to eq(xattribute_val)
          end
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
