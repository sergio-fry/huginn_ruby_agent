module HuginnRubyAgent
  class Agent
    def initialize(code:)
      @code = code
    end

    def check
    end

    def events
      [{message: 'hello'}]
    end
  end
end
