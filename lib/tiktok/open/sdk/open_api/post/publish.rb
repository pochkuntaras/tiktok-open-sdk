# frozen_string_literal: true

# Provides methods to interact with TikTok Open API post endpoints.
module Tiktok
  module Open
    module Sdk
      module OpenApi
        module Post
          # Provides methods for handling TikTok Open API post endpoints.
          module Publish
            extend self

            include ::Tiktok::Open::Sdk::Helpers::ResponseHelper
            include ::Tiktok::Open::Sdk::Helpers::Validators::TokenValidator

            # Queries creator information from the TikTok Open API.
            #
            # @param access_token [String] OAuth2 access token for authentication.
            # @return [Hash] Parsed API response containing creator information.
            # @raise [::Tiktok::Open::Sdk::RequestValidationError] If the access token is invalid.
            #
            # @example
            #   Tiktok::Open::Sdk.post.creator_info_query(access_token: 'your_access_token')
            def creator_info_query(access_token:)
              validate_token!(access_token)

              render_response Tiktok::Open::Sdk::HttpClient.post(
                Tiktok::Open::Sdk.config.creator_info_query_url,
                headers: {
                  Authorization: "Bearer #{access_token}"
                }
              )
            end
          end
        end
      end
    end
  end
end
