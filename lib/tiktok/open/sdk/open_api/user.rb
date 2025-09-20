# frozen_string_literal: true

# Provides methods to interact with TikTok Open API user endpoints.
module Tiktok
  module Open
    module Sdk
      module OpenApi
        # Provides user-related methods for the TikTok Open API.
        module User
          # List of valid user info fields that can be requested from the API.
          FIELDS = %w[
            open_id
            union_id
            avatar_url
            avatar_url_100
            avatar_large_url
            display_name
            bio_description
            profile_deep_link
            is_verified
            username
            follower_count
            following_count
            likes_count
            video_count
          ].freeze

          extend self

          include ::Tiktok::Open::Sdk::Helpers::ResponseHelper
          include ::Tiktok::Open::Sdk::Helpers::Validators::TokenValidator

          # Retrieves user information from the TikTok Open API.
          #
          # @param access_token [String] OAuth2 access token for authentication.
          # @param fields [Array<String>] User fields to retrieve. Must be a subset of FIELDS.
          # @param validate [Boolean] Whether to validate the token and fields. Defaults to true.
          # @return [Hash] Parsed API response containing user information.
          # @raise [::Tiktok::Open::Sdk::RequestValidationError] If the access token or any requested field is invalid.
          def get_user_info(access_token:, fields:, validate: true)
            if validate
              validate_token!(access_token)
              validate_fields!(fields)
            end

            render_response Tiktok::Open::Sdk::HttpClient.get(
              Tiktok::Open::Sdk.config.user_info_url,
              params:  {
                fields: fields.join(',')
              },
              headers: {
                Authorization: "Bearer #{access_token}"
              }
            )
          end

          private

          # Ensures all requested fields are supported by the API.
          #
          # @param fields [Array<String>] Fields to validate against FIELDS.
          # @raise [::Tiktok::Open::Sdk::RequestValidationError] If any field is not supported.
          def validate_fields!(fields)
            invalid = fields - FIELDS

            return if invalid.empty?

            raise ::Tiktok::Open::Sdk::RequestValidationError, "Invalid fields: #{invalid.join(", ")}"
          end
        end
      end
    end
  end
end
