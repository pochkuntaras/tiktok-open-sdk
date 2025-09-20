# frozen_string_literal: true

module Tiktok
  module Open
    module Sdk
      module Helpers
        module Validators
          # Provides token validation methods for TikTok Open SDK.
          module TokenValidator
            # Regular expression to validate tokens.
            # Ensures the token consists of at least 10 printable characters.
            TOKEN_REGEX = /\A[[:print:]]{10,}\z/

            # Checks if the given token is a valid string of at least 10 printable characters.
            #
            # @param token [String] The token to check.
            # @return [Boolean] true if the token is valid, false otherwise.
            def valid_token?(token)
              token.is_a?(String) && !token.empty? && TOKEN_REGEX.match?(token)
            end

            # Validates the given token and raises an error if it is invalid.
            #
            # @param token [String] The token to validate.
            # @raise [::Tiktok::Open::Sdk::RequestValidationError] if the token is invalid.
            # @return [void]
            def validate_token!(token)
              return if valid_token?(token)

              raise ::Tiktok::Open::Sdk::RequestValidationError,
                    'Invalid token format: must be at least 10 printable characters.'
            end
          end
        end
      end
    end
  end
end
