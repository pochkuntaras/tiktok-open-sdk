# frozen_string_literal: true

require 'uri'

module Tiktok
  module Open
    module Sdk
      module OpenApi
        module Auth
          # Provides user authentication helper methods for the TikTok Open SDK.
          module User
            extend self

            include StringUtils

            # Constructs the TikTok OAuth authorization URI.
            #
            # @param params [Hash] Optional query parameters to override defaults.
            #   - :scope [String] (optional) Comma-separated scopes to request.
            #   - :redirect_uri [String] (optional) Redirect URI for the OAuth callback.
            #   - :state [String] (optional) State parameter for CSRF protection.
            # @return [URI] The constructed authorization URI.
            def authorization_uri(params = {})
              allowed_params = params.slice(:scope, :redirect_uri, :state)
              uri            = URI(Tiktok::Open::Sdk.config.user_auth.auth_url)
              query_params   = authorization_uri_default_params.merge(allowed_params)
              uri.query      = URI.encode_www_form(query_params)

              uri
            end

            # Exchanges an authorization code for an access token.
            #
            # @param code [String] The authorization code received from TikTok.
            # @param redirect_uri [String] The redirect URI used in the authorization request.
            #   Defaults to the configured redirect URI.
            # @return [Hash] The parsed response, including:
            #   - :success [Boolean] Whether the request was successful.
            #   - :code [Integer] HTTP status code.
            #   - :response [Hash] Parsed response body or raw string if parsing fails.
            def fetch_access_token(code:, redirect_uri: Tiktok::Open::Sdk.config.user_auth.redirect_uri)
              render_response Tiktok::Open::Sdk::HttpClient.post(
                Tiktok::Open::Sdk.config.user_auth.token_url,
                headers: headers,
                body:    credentials.merge(
                  code:         code,
                  grant_type:   'authorization_code',
                  redirect_uri: redirect_uri
                )
              )
            end

            # Exchanges a refresh token for a new access token.
            #
            # @param refresh_token [String] The refresh token issued by TikTok.
            # @return [Hash] The parsed response, including:
            #   - :success [Boolean] Whether the request was successful.
            #   - :code [Integer] HTTP status code.
            #   - :response [Hash] Parsed response body or raw string if parsing fails.
            def refresh_access_token(refresh_token:)
              render_response Tiktok::Open::Sdk::HttpClient.post(
                Tiktok::Open::Sdk.config.user_auth.token_url,
                headers: headers,
                body:    credentials.merge(
                  grant_type:    'refresh_token',
                  refresh_token: refresh_token
                )
              )
            end

            # Revokes an access token using the provided refresh token.
            #
            # @param token [String] The refresh token to revoke.
            # @return [Hash] The parsed response, including:
            #   - :success [Boolean] Whether the request was successful.
            #   - :code [Integer] HTTP status code.
            #   - :response [Hash] Parsed response body or raw string if parsing fails.
            def revoke_access_token(token:)
              render_response Tiktok::Open::Sdk::HttpClient.post(
                Tiktok::Open::Sdk.config.user_auth.revoke_token_url,
                headers: headers,
                body:    credentials.merge(token: token)
              )
            end

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
