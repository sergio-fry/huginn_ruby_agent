require 'huginn_ruby_agent'
require 'huginn_ruby_agent/sdk'

module HuginnRubyAgent
  describe SDK do
    subject(:sdk) { described_class.new }

    def transfered(data)
      sdk.deserialize(sdk.serialize(data))
    end

    def expect_to_transfer_safe(data)
      expect(transfered(data)).to eq data
    end

    it { expect_to_transfer_safe(1) }
    it { expect_to_transfer_safe({}) }
    it { expect_to_transfer_safe({ payload: 1 }) }
    it { expect_to_transfer_safe({ action: :create_event, payload: { number: 1 } }) }
    it { expect_to_transfer_safe({:action=>:create_event, :payload=>{:message=>"hello"}}) }

    context do
      let(:serialized) { "BAh7BzoLYWN0aW9uOhFjcmVhdGVfZXZlbnQ6DHBheWxvYWR7BjoMbWVzc2FnZUkiCmhlbGxvBjoGRVQ=" }
      it { expect(sdk.deserialize(serialized)).to eq({:action=>:create_event, :payload=>{:message=>"hello"}}) }
    end
  end
end
