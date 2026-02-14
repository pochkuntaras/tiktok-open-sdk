# frozen_string_literal: true

module Tiktok
  module Open
    module Sdk
      module Helpers
        module Validators
          # Validates source information for TikTok video publishing.
          #
          # This module provides validation methods for video source parameters including
          # source type (PULL_FROM_URL or FILE_UPLOAD) and their respective required fields.
          #
          # @example Including the validator in a class
          #   class VideoPublisher
          #     include Tiktok::Open::Sdk::Helpers::Validators::SourceInfoValidator
          #
          #     def publish(source_info)
          #       validate_source_info!(source_info)
          #       # proceed with publishing
          #     end
          #   end
          #
          # @example Validating PULL_FROM_URL source
          #   source_info = {
          #     source: 'PULL_FROM_URL',
          #     video_url: 'https://example.com/video.mp4'
          #   }
          #   validate_source_info!(source_info)
          #
          # @example Validating FILE_UPLOAD source
          #   source_info = {
          #     source: 'FILE_UPLOAD',
          #     video_size: 10_485_760,
          #     chunk_size: 1_048_576,
          #     total_chunk_count: 10
          #   }
          #   validate_source_info!(source_info)
          module SourceInfoValidator
            # Valid source options for video uploads
            SOURCE_OPTIONS = %w[
              PULL_FROM_URL
              FILE_UPLOAD
            ].freeze

            # Validates source information and raises an error if invalid.
            #
            # @param source_info [Hash, nil] The source information to validate
            # @option source_info [String] :source Required. Must be 'PULL_FROM_URL' or 'FILE_UPLOAD'
            # @option source_info [String] :video_url Required for PULL_FROM_URL. Non-empty video URL
            # @option source_info [Integer] :video_size Required for FILE_UPLOAD. Positive integer
            # @option source_info [Integer] :chunk_size Optional for FILE_UPLOAD. Positive integer
            # @option source_info [Integer] :total_chunk_count Optional for FILE_UPLOAD. Positive integer
            #
            # @return [void]
            # @raise [Tiktok::Open::Sdk::RequestValidationError] If validation fails
            #
            # @example Valid PULL_FROM_URL source
            #   validate_source_info!(source: 'PULL_FROM_URL', video_url: 'https://example.com/video.mp4')
            #
            # @example Valid FILE_UPLOAD source
            #   validate_source_info!(source: 'FILE_UPLOAD', video_size: 10_485_760)
            #
            # @example Invalid source type
            #   validate_source_info!(source: 'INVALID')
            #   # => raises RequestValidationError with source error
            def validate_source_info!(source_info)
              errors = {}

              validate_source_info(source_info, errors)

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

            # Validates source information and accumulates errors.
            #
            # @param source_info [Hash, nil] The source information to validate
            # @param errors [Hash] The hash to accumulate errors into
            # @return [void]
            def validate_source_info(source_info, errors)
              if source_info.is_a?(Hash)
                validate_source_specific_fields!(source_info, errors)
              else
                add_error errors, :source_info, 'must be a Hash'
              end
            end

            # Validates source-specific required fields based on source type.
            #
            # @param source_info [Hash] The source information containing type-specific fields
            # @param errors [Hash] The hash to accumulate errors into
            # @return [void]
            def validate_source_specific_fields!(source_info, errors)
              case source_info[:source]
              when 'PULL_FROM_URL'
                validate_pull_from_url_fields!(source_info, errors)
              when 'FILE_UPLOAD'
                validate_file_upload_fields!(source_info, errors)
              else
                add_error errors, :source, "must be one of: #{SOURCE_OPTIONS.join(", ")}"
              end
            end

            # Validates required fields for PULL_FROM_URL source type.
            #
            # @param source_info [Hash] The source information
            # @param errors [Hash] The hash to accumulate errors into
            # @return [void]
            def validate_pull_from_url_fields!(source_info, errors)
              video_url = source_info[:video_url]

              return if video_url.is_a?(String) && !video_url.empty?

              add_error errors, :video_url, 'is required and must be a non-empty string for PULL_FROM_URL'
            end

            # Validates required fields for FILE_UPLOAD source type.
            #
            # @param source_info [Hash] The source information
            # @param errors [Hash] The hash to accumulate errors into
            # @return [void]
            def validate_file_upload_fields!(source_info, errors)
              validate_video_size!        source_info[:video_size],        errors
              validate_chunk_size!        source_info[:chunk_size],        errors
              validate_total_chunk_count! source_info[:total_chunk_count], errors
            end

            # Validates video size for FILE_UPLOAD source.
            #
            # @param video_size [Integer, nil] The video size in bytes
            # @param errors [Hash] The hash to accumulate errors into
            # @return [void]
            def validate_video_size!(video_size, errors)
              return if video_size.is_a?(Integer) && video_size.positive?

              add_error errors, :video_size, 'is required and must be a positive integer for FILE_UPLOAD'
            end

            # Validates chunk size for FILE_UPLOAD source.
            #
            # @param value [Integer, nil] The chunk size in bytes
            # @param errors [Hash] The hash to accumulate errors into
            # @return [void]
            def validate_chunk_size!(value, errors)
              return if value.nil? || (value.is_a?(Integer) && value.positive?)

              add_error errors, :chunk_size, 'must be a positive integer if provided'
            end

            # Validates total chunk count for FILE_UPLOAD source.
            #
            # @param value [Integer, nil] The total number of chunks
            # @param errors [Hash] The hash to accumulate errors into
            # @return [void]
            def validate_total_chunk_count!(value, errors)
              return if value.nil? || (value.is_a?(Integer) && value.positive?)

              add_error errors, :total_chunk_count, 'must be a positive integer if provided'
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
