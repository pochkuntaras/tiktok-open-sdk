# frozen_string_literal: true

module Tiktok
  module Open
    module Sdk
      module Helpers
        # Helper methods for formatting HTTP responses across the SDK.
        module ResponseHelper
          include ::Tiktok::Open::Sdk::Helpers::StringUtilsHelper

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
