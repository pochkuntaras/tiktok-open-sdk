# frozen_string_literal: true

module Tiktok
  module Open
    module Omniauth
      module Strategies
        # OmniAuth strategy for TikTok Open Platform.
        #
        # Integrates TikTok OAuth2 authentication with OmniAuth.
        #
        # @example
        #   use OmniAuth::Builder do
        #     provider :tiktok_open, 'CLIENT_KEY', 'CLIENT_SECRET'
        #   end
        #
        # Supported scopes and their user info fields:
        #   - user.info.basic:   open_id, union_id, display_name, avatar_url, avatar_url_100, avatar_large_url
        #   - user.info.profile: profile_deep_link, bio_description, is_verified, username
        #   - user.info.stats:   follower_count, following_count, likes_count, video_count
        class TiktokOpenSdk < ::OmniAuth::Strategies::OAuth2
          # Custom access token class for TikTok.
          class AccessToken < ::OAuth2::AccessToken; end

          # Maps TikTok OAuth scopes to user info fields.
          SCOPE_FIELDS = {
            'user.info.basic'   => %w[open_id union_id display_name avatar_url avatar_url_100 avatar_large_url],
            'user.info.profile' => %w[profile_deep_link bio_description is_verified username],
            'user.info.stats'   => %w[follower_count following_count likes_count video_count]
          }.freeze

          private_constant :SCOPE_FIELDS

          # The name of this OmniAuth strategy.
          option :name, :tiktok_open_sdk

          # OAuth2 client options for TikTok endpoints.
          #   - :site: TikTok Open API base URL
          #   - :authorize_url: TikTok OAuth2 authorization endpoint
          #   - :token_url: TikTok OAuth2 token endpoint
          option :client_options, {
            site:             ::Tiktok::Open::Sdk::Config::OPEN_API_BASE_URL,
            authorize_url:    ::Tiktok::Open::Sdk.config.user_auth.auth_url,
            token_url:        ::Tiktok::Open::Sdk.config.user_auth.token_url,
            auth_scheme:      :request_body,
            auth_token_class: AccessToken
          }

          # List of parameters allowed in the authorization request.
          option :authorize_options, %i[scope state redirect_uri]

          # Default scope and redirect_uri from SDK config.
          option :scope, ::Tiktok::Open::Sdk.config.user_auth.scopes.join(',')
          option :redirect_uri, ::Tiktok::Open::Sdk.config.user_auth.redirect_uri

          # Returns the unique TikTok user ID (open_id).
          #
          # @return [String] TikTok user's open_id.
          uid { raw_info[:open_id].to_s }

          # Returns a hash of user information.
          #
          # @return [Hash] User info with :name and :image keys, and profile fields if scope is present.
          info do
            { name: raw_info[:display_name], image: raw_info[:avatar_url_100] }.tap do |info|
              if request_scopes.include?('user.info.profile')
                info.merge!(raw_info.slice(:username, :bio_description, :profile_deep_link))
              end
            end
          end

          # Returns extra raw user information from TikTok.
          #
          # @return [Hash] Raw user info data from TikTok API.
          extra { raw_info }

          # Returns the callback URL without query parameters.
          #
          # @return [String] Callback URL.
          def callback_url
            super.split('?').first
          end

          # Builds the access token from TikTok's token endpoint.
          #
          # @raise [OAuth2::Error] if the token response is unsuccessful.
          # @return [AccessToken] OAuth2 access token object.
          def build_access_token
            response = fetch_access_token
            validate_token_response(response)
            create_access_token(response[:response])
          end

          # Handles the initial OAuth2 request phase.
          #
          # @raise [ArgumentError] if client_secret is present in params.
          def request_phase
            params = authorize_params.merge('response_type' => 'code')

            if params.key?(:client_secret) || params.key?('client_secret')
              raise ArgumentError, 'client_secret is not allowed in authorize URL query params'
            end

            redirect client.authorize_url(params)
          end

          # Builds the authorization parameters for the OAuth2 request,
          # adding the TikTok client_key.
          #
          # @return [Hash] Authorization parameters.
          def authorize_params
            super.tap do |params|
              params[:client_key] = options.client_id
            end
          end

          private

          # Fetches access token from TikTok API
          #
          # @return [Hash] Token response from TikTok
          def fetch_access_token
            Tiktok::Open::Sdk.user_auth.fetch_access_token(
              code:         request.params['code'],
              redirect_uri: callback_url
            )
          end

          # Validates the token response
          #
          # @param response [Hash] Token response
          # @raise [OAuth2::Error] if response is unsuccessful
          def validate_token_response(response)
            raise OAuth2::Error, response[:response] unless response[:success]
          end

          # Creates AccessToken from response data
          #
          # @param data [Hash] Token data from response
          # @return [AccessToken] OAuth2 access token object
          def create_access_token(data)
            AccessToken.from_hash(
              client,
              access_token:  data[:access_token],
              refresh_token: data[:refresh_token],
              expires_at:    Time.now.to_i + data[:expires_in].to_i
            )
          end

          # Returns the list of requested OAuth scopes.
          #
          # @return [Array<String>] List of scope strings.
          def request_scopes
            @request_scopes ||= request.params.fetch('scopes', 'user.info.basic').split(',')
          end

          # Returns the list of user info fields to request from TikTok,
          # based on the requested scopes.
          #
          # @return [Array<String>] List of user info field names.
          def user_info_fields
            request_scopes.flat_map { |scope| SCOPE_FIELDS[scope] }.compact
          end

          # Fetches and memoizes the raw user info from the TikTok API.
          #
          # @return [Hash] Raw user info data, or empty hash if unavailable.
          def raw_info
            @raw_info ||= Tiktok::Open::Sdk.user.get_user_info(
              access_token: access_token.token,
              fields:       user_info_fields
            ).dig(:response, :data, :user) || {}
          end
        end
      end
    end
  end
end
