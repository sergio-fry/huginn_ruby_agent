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
end
