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
      Bundler.with_original_env do
        Open3.popen3("ruby", chdir: '/') do |input, output, err, thread|
          sdk = SDK.new
          input.write sdk.code
          input.write @code
          input.write <<~CODE

          Agent.new(Huginn::API.new).check

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

    def receive(events)
      Bundler.with_original_env do
        Open3.popen3("ruby", chdir: '/') do |input, output, err, thread|
          sdk = SDK.new
          input.write sdk.code
          input.write @code
          input.write <<~CODE

          Agent.new(Huginn::API.new).receive(
            JSON.parse(
              Base64.decode64(
                "#{Base64.encode64(events.to_json)}"
              ),
              symbolize_names: true
            )
          )

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

    def create_event(payload)
      @events << payload
    end

    def log(message)
      @logs << message
    end

    def error(message)
      @errors << message
    end

    private

    def log_errors(err)
      err.read.lines.each do |line|
        error line.strip
      end
    end
  end
end
