require 'huginn_ruby_agent'
require 'huginn_ruby_agent/agent'

module HuginnRubyAgent
  describe Agent do
    example do
      code = <<~CODE
        class Agent
          def initialize(api)
            @api = api
          end

          def check
            @api.create_event({ message: 'hello' })
          end
        end
      CODE

      agent = described_class.new(code: code)
      agent.check

      expect(agent.events.size).to eq 1
      expect(agent.events[0]).to eq(message: 'hello')
    end
  end
end

