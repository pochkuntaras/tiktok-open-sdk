# frozen_string_literal: true

require 'json'

module Tiktok
  module Open
    module Sdk
      module OpenApi
        module Auth
          # Shared authentication helper methods for TikTok Open SDK auth modules.
          module Helpers
            include StringUtils

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

            # Parses and formats the HTTP response.
            #
            # @param response [Net::HTTPResponse] The HTTP response object.
            # @return [Hash] The formatted response with keys:
            #   - :success [Boolean] Whether the response is a Net::HTTPSuccess.
            #   - :code [Integer] HTTP status code.
            #   - :response [Hash] Parsed JSON body or a hash with the raw string if parsing fails.
            def render_response(response)
              {
                success:  response.is_a?(Net::HTTPSuccess),
                code:     response.code.to_i,
                response: parse_json(response.body)
              }
            end
          end
        end
      end
    end
  end
end
