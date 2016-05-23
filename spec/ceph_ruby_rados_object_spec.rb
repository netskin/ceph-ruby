require 'spec_helper'

describe CephRuby::RadosObject do
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

  describe 'Named Rados Object' do
    let(:rados_object) { pool.rados_object(object_name) }
    subject { rados_object }
    let(:xattribute_key) { 'testxattr_key' }
    let(:xattribute_val) { 'testxattr_value' }

    it 'Should be a ::CephRuby::RadosObject object' do
      expect(subject).to be_a ::CephRuby::RadosObject
    end

    it 'should respond to name with the name passed to the constructor' do
      expect(subject.name).to equal object_name
    end

    describe 'should respond to' do
      it 'write' do
        expect(subject).to respond_to :write
      end

      it 'overwrite' do
        expect(subject).to respond_to :overwrite
      end

      it 'append' do
        expect(subject).to respond_to :append
      end

      it 'read' do
        expect(subject).to respond_to :read
      end

      it 'destroy' do
        expect(subject).to respond_to :destroy
      end

      it 'resize' do
        expect(subject).to respond_to :resize
      end

      it 'xattr' do
        expect(subject).to respond_to :xattr
      end

      it 'xattr_enumerator' do
        expect(subject).to respond_to :xattr_enumerator
      end

      it 'stat' do
        expect(subject).to respond_to :stat
      end

      it 'size' do
        expect(subject).to respond_to :size
      end

      it 'mtime' do
        expect(subject).to respond_to :mtime
      end

      it 'exist?' do
        expect(subject).to respond_to 'exist?'
      end

      it 'exists?' do
        expect(subject).to respond_to 'exists?'
      end
    end

    describe 'object interaction ' do
      let(:content) do
        'sample text sample text sample text sample text '\
        'sample text sample text sample text sample text sample text'
      end
      let(:larger_content) do
        'larger sample text larger sample text larger sample '\
        'text larger sample text larger sample text larger sample '\
        'text larger sample text larger sample text larger sample text'
      end

      describe 'before creation' do
        it 'calling stat should raise an exception' do
          expect { subject.stat }.to raise_exception Errno::ENOENT
        end

        it 'should not exist' do
          expect(subject.exist?).to be false
        end

        it 'should not be readable' do
          expect { subject.read(0, 1) }.to raise_exception Errno::ENOENT
        end

        it 'should be able to write data to the object' do
          expect { subject.write(0, content) }.not_to raise_exception
        end
      end

      describe 'once created' do
        it 'should exist' do
          expect(subject.exist?).to be true
        end

        it 'should not raise an exception for stat' do
          expect { subject.stat }.not_to raise_exception
        end

        describe 'stat' do
          subject { rados_object.stat }
          it 'should be a hash' do
            expect(subject).to be_a ::Hash
          end

          describe 'mtime key' do
            it 'should exist' do
              expect(subject.key?(:mtime)).to be true
            end

            it 'should equal object mtime' do
              expect(rados_object.mtime).to eq subject[:mtime]
            end
          end

          describe 'size key' do
            it 'should exist' do
              expect(subject.key?(:size)).to be true
            end

            it 'should equal object size' do
              expect(rados_object.size).to eq subject[:size]
            end
          end
        end

        it 'should have the same object size as smaller content' do
          expect(subject.size).to eq(content.bytesize)
        end

        it 'should match the content on read' do
          expect(subject.read(0, subject.size)).to eq(content)
        end

        describe 'reading the object' do
          let(:limit) { 50 }
          let(:offset) { 5 }

          describe 'with a limit' do
            describe 'with 0 offset' do
              subject { rados_object.read(0, limit) }

              it 'should be #{limit} bytes long' do
                expect(subject.length).to eq(limit)
              end

              it 'should match the content substring for that range' do
                expect(subject).to eq(content[0..(limit - 1)])
              end
            end

            describe 'with an offset' do
              subject { rados_object.read(offset, limit) }

              it 'should be the correct length' do
                expect(subject.length).to eq(limit)
              end

              it 'should match the content substring for that range' do
                expect(subject).to eq(content[offset..(offset + limit - 1)])
              end
            end
          end

          describe 'with no limit' do
            describe 'with an offset' do
              subject { rados_object.read(offset, rados_object.size) }

              it 'should be the correct length' do
                expect(subject.length).to eq(content.bytesize - offset)
              end

              it 'should match the content substring for that range' do
                expect(subject).to eq(content[offset..-1])
              end
            end
          end
        end

        describe 'resize' do
          let(:truncate_size) { 15 }

          it 'should not raise exception' do
            expect { subject.resize(truncate_size) }.not_to raise_exception
          end

          it 'should make the object size equal the new size' do
            expect(subject.size).to eq truncate_size
          end
        end
      end

      describe 'when re-writing with larger content with offset 0' do
        it 'should be able to write data to the object' do
          expect { subject.write(0, larger_content) }.not_to raise_exception
        end

        describe 'after writing larger  content' do
          it 'should have the new object size' do
            expect(subject.size).not_to eq(content.bytesize)
            expect(subject.size).to eq(larger_content.bytesize)
          end

          it 'contents should  match the larger content' do
            expect(subject.read(0, subject.size)).to eq(larger_content)
          end
        end

        describe 'when re-re-writing the smaller content with 0 offset' do
          before { subject.write(0, content) }
          it 'should match the larger file size' do
            expect(subject.size).to eq(larger_content.bytesize)
          end
        end
      end

      describe 'when overwriting with the smaller content' do
        it 'should be able to overwrite the object' do
          expect { subject.overwrite(content) }.not_to raise_exception
        end

        it 'should have the correct size' do
          expect(subject.size).to eq(content.bytesize)
        end
      end

      describe 'when appending with the smaller content' do
        it 'should not raise exception' do
          expect { subject.append(content) }.not_to raise_exception
        end

        it 'should increase the file size by content.bytesize' do
          expect(subject.size).to eq(2 * content.bytesize)
        end

        it 'has added the smaller content to the file' do
          expect(subject.read(0, subject.size)).to eq("#{content}#{content}")
        end
      end

      describe 'on destroying the object' do
        it 'should not throw an exception' do
          expect { subject.destroy }.not_to raise_exception
        end

        describe 'after destroying file' do
          it 'should raise an exception on stat' do
            expect { subject.stat }.to raise_exception Errno::ENOENT
          end

          it 'should not exist' do
            expect(subject.exist?).to be false
          end

          describe 'when appending' do
            it 'should be able to append with larger content' do
              expect { subject.append(larger_content) }.not_to raise_exception
            end

            it 'should have larger content size' do
              expect(subject.size).to eq(larger_content.bytesize)
            end

            it 'should still be destroyable' do
              expect { subject.destroy }.not_to raise_exception
            end
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
