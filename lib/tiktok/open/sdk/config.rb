# frozen_string_literal: true

module Tiktok
  module Open
    module Sdk
      # Configuration class for TikTok Open SDK.
      #
      # Holds client credentials and user authentication settings.
      #
      # @example
      #   config = Tiktok::Open::Sdk::Config.new
      #   config.client_key = 'your_key'
      #   config.client_secret = 'your_secret'
      #   config.user_auth.scopes = %w[user.info.basic]
      class Config
        # @return [String] The TikTok client key.
        attr_accessor :client_key

        # @return [String] The TikTok client secret.
        attr_accessor :client_secret

        # @return [UserAuth] The user authentication configuration.
        attr_accessor :user_auth

        # Initializes a new Config object with default user authentication settings.
        def initialize
          @user_auth = UserAuth.new
        end

        # User authentication configuration for TikTok Open SDK.
        #
        # Holds OAuth URLs, scopes, and redirect URI.
        class UserAuth
          # @return [String] The OAuth authorization URL.
          attr_accessor :auth_url

          # @return [String] The OAuth token exchange URL.
          attr_accessor :token_url

          # @return [String] The OAuth token revoke URL.
          attr_accessor :revoke_token_url

          # @return [Array<String>] The list of OAuth scopes.
          attr_accessor :scopes

          # @return [String, nil] The OAuth redirect URI.
          attr_accessor :redirect_uri

          # Initializes a new UserAuth object with default URLs and empty scopes.
          def initialize
            @auth_url         = 'https://www.tiktok.com/v2/auth/authorize/'
            @revoke_token_url = 'https://open.tiktokapis.com/v2/oauth/revoke/'
            @token_url        = 'https://open.tiktokapis.com/v2/oauth/token/'
            @scopes           = []
            @redirect_uri     = nil
          end
        end
      end
    end
  end
end
