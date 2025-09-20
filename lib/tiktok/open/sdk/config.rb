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
        # Base domains for constructing TikTok API URLs.
        AUTH_BASE_URL     = 'https://www.tiktok.com'
        OPEN_API_BASE_URL = 'https://open.tiktokapis.com'

        # @!attribute [rw] client_key
        #   @return [String] TikTok client key.
        attr_accessor :client_key

        # @!attribute [rw] client_secret
        #   @return [String] TikTok client secret.
        attr_accessor :client_secret

        # @!attribute [rw] user_info_url
        #   @return [String] TikTok user info endpoint URL.
        attr_accessor :user_info_url

        # @!attribute [rw] user_auth
        #   @return [UserAuth] User authentication configuration.
        attr_accessor :user_auth

        # Create a new Config with default user authentication settings.
        def initialize
          @user_info_url = "#{OPEN_API_BASE_URL}/v2/user/info/"
          @user_auth     = UserAuth.new
        end

        # User authentication configuration for TikTok Open SDK.
        #
        # Holds OAuth URLs, scopes, and redirect URI.
        class UserAuth
          # @!attribute [rw] auth_url
          #   @return [String] OAuth authorization URL.
          attr_accessor :auth_url

          # @!attribute [rw] revoke_token_url
          #   @return [String] OAuth token revocation URL.
          attr_accessor :revoke_token_url

          # @!attribute [rw] token_url
          #   @return [String] OAuth token exchange URL.
          attr_accessor :token_url

          # @!attribute [rw] scopes
          #   @return [Array<String>] List of OAuth scopes.
          attr_accessor :scopes

          # @!attribute [rw] redirect_uri
          #   @return [String, nil] OAuth redirect URI.
          attr_accessor :redirect_uri

          # Initializes a new UserAuth object with default URLs and empty scopes.
          def initialize
            @auth_url         = "#{AUTH_BASE_URL}/v2/auth/authorize/"
            @revoke_token_url = "#{OPEN_API_BASE_URL}/v2/oauth/revoke/"
            @token_url        = "#{OPEN_API_BASE_URL}/v2/oauth/token/"
            @scopes           = []
            @redirect_uri     = nil
          end
        end
      end
    end
  end
end
