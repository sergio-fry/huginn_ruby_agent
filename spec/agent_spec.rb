require 'huginn_ruby_agent'
require 'huginn_ruby_agent/agent'

module HuginnRubyAgent
  describe Agent do
    example '#check produces event' do
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

    example "#check raises error" do
      code = <<~CODE
        class Agent
          def initialize(api)
            @api = api
          end

          def check
            some error here
          end
        end
      CODE

      agent = described_class.new(code: code)
      agent.check

      expect(agent.events).to be_empty
      expect(agent.errors).not_to be_empty
    end
  end
end

