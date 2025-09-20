# frozen_string_literal: true

require 'json'

module Tiktok
  module Open
    module Sdk
      module Helpers
        # Shared authentication helper methods for TikTok Open SDK auth modules.
        module AuthHelper
          private

          # Returns the HTTP headers for requests.
          #
          # @return [Hash] The headers for HTTP requests.
          def headers
            {
              'Content-Type':  'application/x-www-form-urlencoded',
              'Cache-Control': 'no-cache'
            }
          end

          # Returns the client credentials for authentication.
          #
          # @return [Hash] The client credentials.
          def credentials
            {
              client_key:    Tiktok::Open::Sdk.config.client_key,
              client_secret: Tiktok::Open::Sdk.config.client_secret
            }
          end

          # Returns the default query parameters for the authorization URI.
          #
          # @return [Hash] The default query parameters:
          #   - :client_key [String] The TikTok client key.
          #   - :response_type [String] Always 'code'.
          #   - :scope [String] Comma-separated scopes.
          #   - :redirect_uri [String] The redirect URI.
          #   - :state [nil] Default state is nil.
          def authorization_uri_default_params
            {
              client_key:    Tiktok::Open::Sdk.config.client_key,
              response_type: 'code',
              scope:         Tiktok::Open::Sdk.config.user_auth.scopes.join(','),
              redirect_uri:  Tiktok::Open::Sdk.config.user_auth.redirect_uri,
              state:         nil
            }
          end

          # render_response moved to ::Tiktok::Open::Sdk::ResponseHelpers
        end
      end
    end
  end
end
