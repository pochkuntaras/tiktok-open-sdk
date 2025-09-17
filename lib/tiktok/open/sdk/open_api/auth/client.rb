# frozen_string_literal: true

require 'uri'

module Tiktok
  module Open
    module Sdk
      module OpenApi
        module Auth
          # Provides methods for handling TikTok Open API client authentication.
          module Client
            extend self

            include Helpers

            # Fetches a client access token from the TikTok Open API.
            #
            # @return [Hash] The parsed response containing the client token and related data.
            # @example
            #   token_response = Tiktok::Open::Sdk::OpenApi::Auth::Client.fetch_client_token
            def fetch_client_token
              render_response Tiktok::Open::Sdk::HttpClient.post(
                Tiktok::Open::Sdk.config.user_auth.token_url,
                headers: headers,
                body:    credentials.merge(
                  grant_type: 'client_credentials'
                )
              )
            end
          end
        end
      end
    end
  end
end
