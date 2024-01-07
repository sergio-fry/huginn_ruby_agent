require 'json'
require 'base64'

module HuginnRubyAgent
  class SDK
    def serialize(payload)
      Base64.urlsafe_encode64(payload.to_json)
    end

    def deserialize(serialized_payload)
      JSON.parse Base64.urlsafe_decode64(serialized_payload.strip), symbolize_names: true
    end

    def code
      <<~CODE
        require 'json'
        require 'base64'

        module Huginn
          class API
            def initialize(serialized_credentials: nil)
              @credentials = serialized_credentials.nil? ? {} : deserialize(serialized_credentials) 
            end

            def serialize(payload)
              Base64.urlsafe_encode64(payload.to_json)
            end

            def deserialize(serialized_payload)
              JSON.parse Base64.urlsafe_decode64(serialized_payload.strip), symbolize_names: true
            end

            def create_event(payload)
              puts serialize({ action: :create_event, payload: payload })
            end

            def log(message)
              puts serialize({ action: :log, payload: message })
            end

            def error(message)
              puts serialize({ action: :error, payload: message })
            end
          end
        end
      CODE
    end
  end
end
