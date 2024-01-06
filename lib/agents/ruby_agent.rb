# frozen_string_literal: true

require 'date'
require 'cgi'
require 'tempfile'
require 'base64'

# https://stackoverflow.com/questions/23884526/is-there-a-safe-way-to-eval-in-ruby-or-a-better-way-to-do-this
module Agents
  class RubyAgent < Agent
    include FormConfigurable

    can_dry_run!

    default_schedule "never"

    # TODO: remove redundant
    gem_dependency_check { defined?(MiniRacer) }

    description <<-MD
      The Ruby Agent allows you to write code in Ruby that can create and receive events.  If other Agents aren't meeting your needs, try this one!

      You should put code in the `code` option.

      You can implement `Agent.check` and `Agent.receive` as you see fit.  The following methods will be available on Agent:

      * `@api.create_event(payload)`
      * `@api.incoming_vents()` (the returned event objects will each have a `payload` property) # TODO
      * `@api.memory()` # TODO
      * `@api.memory(key)` # TODO
      * `@api.memory(keyToSet, valueToSet)` # TODO
      * `@api.set_memory(object)` (replaces the Agent's memory with the provided object) # TODO
      * `@api.delete_key(key)` (deletes a key from memory and returns the value) # TODO
      * `@api.credential(name)` # TODO
      * `@api.credential(name, valueToSet)` # TODO
      * `@api.options()` # TODO
      * `@api.options(key)` # TODO
      * `@api.log(message)`
      * `@api.error(message)`
    MD

    form_configurable :code, type: :text, ace: true
    form_configurable :expected_receive_period_in_days
    form_configurable :expected_update_period_in_days

    def validate_options
      errors.add(:base, "The 'code' option is required") unless options['code'].present?
    end

    def working?
      return false if recent_error_logs?

      if interpolated['expected_update_period_in_days'].present?
        return false unless event_created_within?(interpolated['expected_update_period_in_days'])
      end

      if interpolated['expected_receive_period_in_days'].present?
        return false unless last_receive_at && last_receive_at > interpolated['expected_receive_period_in_days'].to_i.days.ago
      end

      true
    end

    def check
      log_errors do
        execute_check
      end
    end

    def receive(events)
      log_errors do
        execute_receive(events)
      end
    end

    def default_options
      code = <<~CODE

        require "bundler/inline"

        gemfile do
          source "https://rubygems.org"

          # gem "mechanize"
        end

        class Agent
          def initialize(api)
            @api = api
          end

          def check
            @api.create_event({ message: 'I made an event!' })
          end

          def receive(incoming_events)
            incoming_events.each do |event|
              @api.create_event({ message: 'new event', event_was: event[:payload] })
            end
          end
        end
      CODE

      {
        'code' => code,
        'expected_receive_period_in_days' => '2',
        'expected_update_period_in_days' => '2'
      }
    end

    private

    def execute_check
      Bundler.with_original_env do
        Open3.popen3("ruby", chdir: '/') do |input, output, err, thread|
          input.write sdk_code
          input.write code
          input.write <<~CODE

          Agent.new(Huginn::API.new).check

          CODE
          input.close


          output.readlines.map { |line| JSON.parse(line, symbolize_names: true) }.each do |data|
            case data[:action]
            when 'create_event'
              create_event(payload: data[:payload])
            when 'log'
              log data[:payload]
            when 'error'
              error data[:payload]
            end
          end

          errors = err.read

          error err.read
          log "thread #{thread.value}"
        end
      end
    end

    def execute_receive(events)
      Bundler.with_original_env do
        Open3.popen3("ruby", chdir: '/') do |input, output, err, thread|
          input.write sdk_code
          input.write code
          input.write <<~CODE

          api = Huginn::API.new
          begin
            Agent.new(api).receive(
              JSON.parse(
                Base64.decode64(
                  "#{Base64.encode64(events.to_json)}"
                ),
                symbolize_names: true
              )
            )
          rescue StandardError => ex
            api.error ex
          end

          CODE
          input.close


          output.readlines.map { |line| JSON.parse(line, symbolize_names: true) }.each do |data|
            case data[:action]
            when 'create_event'
              create_event(payload: data[:payload])
            when 'log'
              log data[:payload]
            when 'error'
              error data[:payload]
            end
          end

          errors = err.read

          error err.read
          log "thread #{thread.value}"
        end
      end
    end

    def code
      interpolated['code']
    end

    def sdk_code
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

    def log_errors
      begin
        yield
      rescue StandardError => e
        error "Runtime error: #{e.message}"
      end
    end
  end
end
