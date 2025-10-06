# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter 'spec/'
  add_filter '.github'
  add_filter 'lib/tiktok/open/sdk/version'
end

require 'webmock/rspec'
require 'omniauth'
require 'omniauth-oauth2'
require 'tiktok/open/sdk'

Tiktok::Open::Sdk.configure do |config|
  config.client_key             = 'test_client_key'
  config.client_secret          = 'test_client_secret'
  config.user_auth.scopes       = %w[user.info.basic user.info.profile]
  config.user_auth.redirect_uri = 'https://example.com/auth/tiktok_open_sdk/callback'
end

require 'tiktok/open/omniauth/strategies/tiktok_open_sdk'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
