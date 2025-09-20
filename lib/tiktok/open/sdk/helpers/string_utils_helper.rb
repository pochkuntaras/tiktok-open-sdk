# frozen_string_literal: true

require 'json'

module Tiktok
  module Open
    module Sdk
      module Helpers
        # Utility methods for string and JSON handling.
        module StringUtilsHelper
          # Parses a JSON string into a Ruby hash with symbolized keys.
          #
          # @param str [String] JSON string to parse.
          # @return [Hash] Parsed hash with symbolized keys, or a hash with the raw string if parsing fails.
          def parse_json(str)
            JSON.parse(str, symbolize_names: true)
          rescue JSON::ParserError
            { raw: str }
          end
        end
      end
    end
  end
end
