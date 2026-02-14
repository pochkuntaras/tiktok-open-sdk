# frozen_string_literal: true

module Tiktok
  module Open
    module Sdk
      module Helpers
        module Validators
          # Validates post information for TikTok video publishing.
          #
          # This module provides validation methods for post-related parameters including
          # privacy level, title, boolean flags, and video cover timestamp.
          #
          # @example Including the validator in a class
          #   class VideoPublisher
          #     include Tiktok::Open::Sdk::Helpers::Validators::PostInfoValidator
          #
          #     def publish(post_info)
          #       validate_post_info!(post_info)
          #       # proceed with publishing
          #     end
          #   end
          #
          # @example Validating post information
          #   post_info = {
          #     privacy_level: 'PUBLIC_TO_EVERYONE',
          #     title: 'My awesome video',
          #     disable_duet: false,
          #     brand_content_toggle: true
          #   }
          #   validate_post_info!(post_info)
          module PostInfoValidator
            # Valid privacy level options for TikTok videos
            PRIVACY_LEVEL_OPTIONS = %w[
              PUBLIC_TO_EVERYONE
              MUTUAL_FOLLOW_FRIENDS
              FOLLOWER_OF_CREATOR
              SELF_ONLY
            ].freeze

            # Maximum allowed length for video title
            MAX_TITLE_LENGTH = 2200

            # Validates post information and raises an error if invalid.
            #
            # @param post_info [Hash, nil] The post information to validate
            # @option post_info [String] :privacy_level Required. Must be one of PRIVACY_LEVEL_OPTIONS
            # @option post_info [String] :title Optional. Maximum 2200 characters
            # @option post_info [Boolean] :disable_duet Optional. Boolean flag
            # @option post_info [Boolean] :disable_stitch Optional. Boolean flag
            # @option post_info [Boolean] :disable_comment Optional. Boolean flag
            # @option post_info [Boolean] :brand_content_toggle Optional. Boolean flag
            # @option post_info [Boolean] :brand_organic_toggle Optional. Boolean flag
            # @option post_info [Boolean] :is_aigc Optional. Boolean flag
            # @option post_info [Integer] :video_cover_timestamp_ms Optional. Non-negative integer
            #
            # @return [void]
            # @raise [Tiktok::Open::Sdk::RequestValidationError] If validation fails
            #
            # @example Valid post information
            #   validate_post_info!(privacy_level: 'PUBLIC_TO_EVERYONE')
            #
            # @example Invalid privacy level
            #   validate_post_info!(privacy_level: 'INVALID')
            #   # => raises RequestValidationError with privacy_level error
            def validate_post_info!(post_info)
              errors = {}

              validate_post_info(post_info, errors)

              raise_validation_errors!(errors)
            end

            private

            # Raises validation errors if any exist.
            #
            # @param errors [Hash] The accumulated validation errors
            # @return [void]
            # @raise [Tiktok::Open::Sdk::RequestValidationError] If errors is not empty
            def raise_validation_errors!(errors)
              raise ::Tiktok::Open::Sdk::RequestValidationError, errors unless errors.empty?
            end

            # Validates post information and accumulates errors.
            #
            # @param post_info [Hash, nil] The post information to validate
            # @param errors [Hash] The hash to accumulate errors into
            # @return [void]
            def validate_post_info(post_info, errors)
              return if post_info.nil?
              return add_error errors, :post_info, 'must be a Hash' unless post_info.is_a?(Hash)

              privacy_level = post_info[:privacy_level]
              title         = post_info[:title]
              timestamp     = post_info[:video_cover_timestamp_ms]

              validate_privacy_level!         privacy_level, errors
              validate_title!                 title,         errors
              validate_boolean_fields!        post_info,     errors
              validate_video_cover_timestamp! timestamp,     errors
            end

            # Validates that privacy level is one of the allowed options.
            #
            # @param privacy_level [String, nil] The privacy level to validate
            # @param errors [Hash] The hash to accumulate errors into
            # @return [void]
            def validate_privacy_level!(privacy_level, errors)
              return if PRIVACY_LEVEL_OPTIONS.include?(privacy_level)

              add_error errors, :privacy_level, "must be one of: #{PRIVACY_LEVEL_OPTIONS.join(", ")}"
            end

            # Validates video title length and type.
            #
            # @param title [String, nil] The title to validate
            # @param errors [Hash] The hash to accumulate errors into
            # @return [void]
            def validate_title!(title, errors)
              return if title.nil?
              return add_error errors, :title, 'must be a String' unless title.is_a?(String)
              return unless title.length > MAX_TITLE_LENGTH

              add_error errors, :title, "must be less than #{MAX_TITLE_LENGTH} characters"
            end

            # Validates that boolean fields contain boolean values.
            #
            # @param post_info [Hash] The post information containing boolean fields
            # @param errors [Hash] The hash to accumulate errors into
            # @return [void]
            def validate_boolean_fields!(post_info, errors)
              boolean_fields = %i[
                disable_duet
                disable_stitch
                disable_comment
                brand_content_toggle
                brand_organic_toggle
                is_aigc
              ]

              boolean_fields.each do |field|
                next unless post_info.key?(field)

                value = post_info[field]
                next if value.is_a?(TrueClass) || value.is_a?(FalseClass)

                add_error errors, field, 'must be a boolean (true or false)'
              end
            end

            # Validates video cover timestamp is a non-negative integer.
            #
            # @param timestamp [Integer, nil] The timestamp to validate
            # @param errors [Hash] The hash to accumulate errors into
            # @return [void]
            def validate_video_cover_timestamp!(timestamp, errors)
              return if timestamp.nil? || (timestamp.is_a?(Integer) && timestamp >= 0)

              add_error errors, :video_cover_timestamp_ms, 'must be a non-negative integer'
            end

            # Adds an error message to the errors hash.
            #
            # @param errors [Hash] The hash to accumulate errors into
            # @param field_name [Symbol] The field name that has an error
            # @param message [String] The error message
            # @return [Hash] The errors hash
            def add_error(errors, field_name, message)
              errors[field_name] ||= [] << message
              errors
            end
          end
        end
      end
    end
  end
end
