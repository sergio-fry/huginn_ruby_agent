# frozen_string_literal: true
require 'huginn_ruby_agent'
require 'huginn_ruby_agent/agent'

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
      * `@api.credential(name)`
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
      running_agent do |agent|
        agent.check
      end
    end

    def receive(events)
      running_agent do |agent|
        agent.receive events
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

    def running_agent
      agent = HuginnRubyAgent::Agent.new(code:, credentials: credentials_hash)
      yield agent

      agent.events.each do |event|
        create_event(payload: event)
      end
      agent.logs.each do |message|
        log message
      end
      agent.errors.each do |message|
        error message
      end
    end

    def code
      interpolated['code']
    end

    def credentials_hash
      Hash[user.user_credentials.map { |c| [c.credential_name, c.credential_value] }]
    end
  end
end
