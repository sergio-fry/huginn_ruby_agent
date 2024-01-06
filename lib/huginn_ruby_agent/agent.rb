require 'open3'
require 'json'

module HuginnRubyAgent
  class SDK
    def code
      <<~CODE
        require 'json'
        require 'base64'

        module Huginn
          class API
            def create_event(payload)
              puts(
                {
                  action: :create_event,
                  payload: payload
                }.to_json
              )
            end

            def log(message)
              puts(
                {
                  action: :log,
                  payload: message
                }.to_json
              )
            end

            def error(message)
              puts(
                {
                  action: :error,
                  payload: message
                }.to_json
              )
            end
          end
        end
      CODE
    end
  end
  class Agent
    attr_reader :events

    def initialize(code:)
      @code = code
      @events = []
      @logs = []
      @errors = []
    end

    def check
      Bundler.with_original_env do
        Open3.popen3("ruby", chdir: '/') do |input, output, err, thread|
          input.write SDK.new.code
          input.write @code
          input.write <<~CODE

          Agent.new(Huginn::API.new).check

          CODE
          input.close


          output.readlines.map { |line| JSON.parse(line, symbolize_names: true) }.each do |data|
            case data[:action]
            when 'create_event'
              create_event(data[:payload])
            when 'log'
              log data[:payload]
            when 'error'
              error data[:payload]
            end
          end

          # TODO log errors
          # error err.read
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
  end
end
