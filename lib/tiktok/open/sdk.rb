# frozen_string_literal: true

require_relative 'sdk/helpers/string_utils_helper'
require_relative 'sdk/helpers/response_helper'
require_relative 'sdk/helpers/auth_helper'
require_relative 'sdk/helpers/validators/token_validator'
require_relative 'sdk/open_api/auth/user'
require_relative 'sdk/open_api/auth/client'
require_relative 'sdk/open_api/post/publish'
require_relative 'sdk/open_api/user'
require_relative 'sdk/version'
require_relative 'sdk/http_client'
require_relative 'sdk/config'

module Tiktok
  module Open
    # Main SDK module providing configuration and error handling
    module Sdk
      # Generic error class for TikTok Open SDK
      #
      # @example
      #   raise Tiktok::Open::Sdk::Error, "Something went wrong"
      class Error < StandardError; end

      class RequestValidationError < Error; end

      class << self
        # SDK configuration object
        #
        # @return [Config, nil]
        attr_accessor :config

        # Configures the TikTok Open SDK.
        #
        # This method yields the configuration object, allowing you to set
        # client credentials and other options.
        #
        # @yieldparam config [Config] the configuration object
        # @return [Config] the configured object
        #
        # @example
        #   Tiktok::Open::Sdk.configure do |config|
        #     config.client_key = 'your_key'
        #     config.client_secret = 'your_secret'
        #     config.user_auth.auth_url = 'https://www.tiktok.com/v2/auth/authorize/'
        #     config.user_auth.token_url = 'https://open.tiktokapis.com/v2/oauth/token/'
        #     config.user_auth.scopes = %w[user.info.basic video.list]
        #     config.user_auth.redirect_uri = 'https://your-redirect-uri.example.com'
        #     config.load_omniauth = true
        #   end
        def configure
          self.config ||= Config.new

          yield(config)

          load_omniauth! if config.load_omniauth

          config
        end

        # Convenience accessor for user authentication functionality
        #
        # @return [OpenApi::Auth::User] the User authentication module
        #
        # @example
        #   Tiktok::Open::Sdk.user_auth.authorization_uri
        def user_auth
          OpenApi::Auth::User
        end

        # Convenience accessor for client authentication functionality
        #
        # @return [OpenApi::Auth::Client] the Client authentication module
        #
        # @example
        #   Tiktok::Open::Sdk.client_auth.fetch_client_token
        def client_auth
          OpenApi::Auth::Client
        end

        # Convenience accessor for post publish functionality
        #
        # @return [OpenApi::Post::Publish] the Post publish module
        #
        # @example
        #   Tiktok::Open::Sdk.post.video_init(access_token: 'token', post_info: post_info, source_info: source_info)
        def post
          OpenApi::Post::Publish
        end

        # Convenience accessor for user functionality
        #
        # @return [OpenApi::User] the User module
        #
        # @example
        #   Tiktok::Open::Sdk.user.info(access_token: 'token')
        def user
          OpenApi::User
        end

        private

        # Loads the OmniAuth strategy for TikTok Open Platform.
        #
        # Attempts to require the necessary OmniAuth dependencies for TikTok Open integration.
        # Raises an error if the required gems are not available.
        #
        # @raise [Tiktok::Open::Sdk::Error] if 'omniauth-oauth2' or the TikTok strategy cannot be loaded
        # @example
        #   Tiktok::Open::Sdk.load_omniauth!
        def load_omniauth!
          require 'omniauth-oauth2'
          require 'tiktok/open/omniauth/strategies/tiktok_open_sdk'
        rescue LoadError => e
          raise ::Tiktok::Open::Sdk::Error,
                "OmniAuth is not loaded! Error: #{e.message}"
        end
      end
    end
  end
end
