require 'open3'
require 'json'
require 'huginn_ruby_agent/sdk'
require 'base64'

module HuginnRubyAgent
  class Agent
    attr_reader :events, :errors

    def initialize(code:)
      @code = code
      @events = []
      @logs = []
      @errors = []
    end

    def check
      execute ".check"
    end

    def receive(events)
      execute ".receive(api.deserialize('#{sdk.serialize(events)}'))"
    end

    def create_event(payload)
      @events << payload
    end

    def log(message)
      @logs << message
    end

    def error(message)
      @errors << message
    end

    def sdk
      @sdk ||= SDK.new
    end

    private

    def execute(command=".check")
      Bundler.with_original_env do
        Open3.popen3("ruby", chdir: '/') do |input, output, err, thread|
          input.write sdk.code
          input.write @code
          input.write <<~CODE

          api = Huginn::API.new
          Agent.new(api)#{command}

          CODE
          input.close

          output.readlines.map { |line| sdk.deserialize(line) }.each do |data|
            case data[:action]
            when :create_event
              create_event(data[:payload])
            when :log
              log data[:payload]
            when :error
              error data[:payload]
            end
          end

          log_errors(err)
        end
      end
    end

    def log_errors(err)
      err.read.lines.each do |line|
        error line.strip
      end
    end
  end
end
