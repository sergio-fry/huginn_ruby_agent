# frozen_string_literal: true

require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::RubyAgent do
  before(:each) do
    @valid_options = Agents::RubyAgent.new.default_options
    @checker = Agents::RubyAgent.new(name: 'RubyAgent', options: @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending 'add specs here'
end
