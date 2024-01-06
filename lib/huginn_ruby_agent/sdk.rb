require 'json'
require 'base64'

module HuginnRubyAgent
  class SDK
    def serialize(payload)
      Base64.urlsafe_encode64(Marshal.dump(payload))
    end

    def deserialize(serialized_payload)
      Marshal.load(Base64.urlsafe_decode64(serialized_payload))
    end

    def code
      <<~CODE
        require 'json'
        require 'base64'

        module Huginn
          class API
            def serialize(payload)
              File.open('/Users/sergei/agent.txt', 'wb') do |file|
                file.puts payload.inspect
                file.puts Marshal.dump(payload)
                file.puts Base64.urlsafe_encode64(Marshal.dump(payload))
              end
              Base64.urlsafe_encode64(Marshal.dump(payload))
            end

            def deserialize(serialized_payload)
              Marshal.load(Base64.urlsafe_decode64(serialized_payload))
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
