# frozen_string_literal: true

require_relative 'post_info_validator'
require_relative 'source_info_validator'

module Tiktok
  module Open
    module Sdk
      module Helpers
        module Validators
          # Provides validation for video publishing initialization parameters.
          #
          # This module combines and applies the `PostInfoValidator` and `SourceInfoValidator` logic
          # for validating `post_info` and `source_info` input hashes typically required for
          # TikTok Open SDK video publishing workflows.
          #
          # @example Including and using PostPublishValidator
          #   class Publisher
          #     include Tiktok::Open::Sdk::Helpers::Validators::PostPublishValidator
          #
          #     def publish_video(params)
          #       validate_video_init_info!(params)
          #       # ...proceed if valid
          #     end
          #   end
          #
          # @see PostInfoValidator#validate_post_info
          # @see SourceInfoValidator#validate_source_info
          module PostPublishValidator
            include PostInfoValidator
            include SourceInfoValidator

            # Validates combined video initialization parameters.
            #
            # Both `post_info` and `source_info` sub-hashes are validated using the appropriate
            # validators. If any errors occur, a RequestValidationError (or similar) is raised.
            #
            # @param params [Hash] The full parameter hash.
            # @option params [Hash] :post_info Info for video post, validated by PostInfoValidator
            # @option params [Hash] :source_info Info on video source, validated by SourceInfoValidator
            #
            # @raise [RequestValidationError] Raised if any validation errors found in either section.
            # @return [void]
            def validate_video_init_info!(params)
              errors = { post_info: {}, source_info: {} }

              validate_post_info   params[:post_info],   errors[:post_info]
              validate_source_info params[:source_info], errors[:source_info]

              raise_validation_errors!(errors) unless errors.values.all?(&:empty?)
            end
          end
        end
      end
    end
  end
end
