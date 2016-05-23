module CephRuby
  # A Completion for callbacks for asynchronous IO
  class RadosCompletion
    attr_accessor :completion_t

    def initialize(args: nil, complete_callback: nil, safe_callback: nil)
      self.completion_t = Lib::Rados.rados_completion(args,
                                                      complete_callback,
                                                      safe_callback)
    end

    def wait_for_complete
    end

    def wait_for_safe
    end

    def complete?
    end

    def safe?
    end

    def wait_for_complete_and_cb
    end

    def wait_for_safe_and_cb
    end

    def complete_and_cb?
    end

    def safe_and_cb?
    end

    def return_value
    end

    def destroy
    end
  end
end
