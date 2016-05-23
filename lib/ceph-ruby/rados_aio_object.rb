module CephRuby
  # Asynchronous object operations on Rados Object
  class RadosAIOObject < RadosObject
    attr_accessor :completions

    def initialize(pool, name)
      super(pool, name)
      self.completions = []
    end

    def read(completion, _offset, _size)
      completions << completion
    end

    def write(completion, _offset, data)
      completions << completion
      size = data.size
      p size
    end

    def destroy(completion)
      completions << completion
    end

    def append(completion, _data)
      completions << completion
    end

    def stat(completion)
      completions << completion
    end

    def cancel(completion)
      completions << completion
    end
  end
end
