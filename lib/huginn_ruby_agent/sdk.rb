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
            attr_reader :changed_credentials

            def initialize(serialized_credentials: nil)
              @serialized_credentials = serialized_credentials
              @changed_credentials = {}
            end

            def credentials
              @credentials ||=
                begin
                  @serialized_credentials.nil? ? {} : deserialize(@serialized_credentials) 
                end
            end

            def serialize(payload)
              Base64.urlsafe_encode64(payload.to_json)
            end

            def deserialize(serialized_payload)
              JSON.parse Base64.urlsafe_decode64(serialized_payload.strip), symbolize_names: true
            end

            def credential(name)
              credentials[name.to_sym]
            end

            def set_credential(name, value)
              credentials[name.to_sym] = value
              changed_credentials[name.to_sym] = value

              puts serialize({ action: :set_credential, payload: { name: name, value: value } })
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
