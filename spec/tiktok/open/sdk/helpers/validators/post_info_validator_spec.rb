# frozen_string_literal: true

RSpec.describe Tiktok::Open::Sdk::Helpers::Validators::PostInfoValidator do
  let(:test_class) do
    Class.new do
      include Tiktok::Open::Sdk::Helpers::Validators::PostInfoValidator
    end
  end

  let(:test_instance) { test_class.new }

  describe '#validate_post_info!' do
    context 'when post_info is nil' do
      it { expect { test_instance.validate_post_info!(nil) }.not_to raise_error }
    end

    context 'when post_info is not a hash' do
      let(:params)   { [] }
      let(:messages) { { post_info: ['must be a Hash'] } }

      it_behaves_like 'RequestValidationError', :validate_post_info!
    end

    context 'when post_info is a valid hash' do
      let(:parama) { { privacy_level: 'PUBLIC_TO_EVERYONE', brand_content_toggle: false } }

      it { expect { test_instance.validate_post_info!(parama) }.not_to raise_error }
    end

    context 'with privacy_level' do
      let(:messages) do
        {
          privacy_level: [
            'must be one of: PUBLIC_TO_EVERYONE, MUTUAL_FOLLOW_FRIENDS, FOLLOWER_OF_CREATOR, SELF_ONLY'
          ]
        }
      end

      context 'when privacy_level is missing' do
        let(:params) { { brand_content_toggle: false } }

        it_behaves_like 'RequestValidationError', :validate_post_info!
      end

      context 'when privacy_level is invalid' do
        let(:params) { { privacy_level: 'INVALID_LEVEL' } }

        it_behaves_like 'RequestValidationError', :validate_post_info!
      end

      context 'with valid privacy levels' do
        it 'accepts all valid privacy level options' do
          described_class::PRIVACY_LEVEL_OPTIONS.each do |privacy_level|
            expect { test_instance.validate_post_info!(privacy_level: privacy_level) }.not_to raise_error
          end
        end
      end
    end

    context 'with title validation' do
      let(:params) { { privacy_level: 'PUBLIC_TO_EVERYONE' } }

      context 'when title is nil' do
        let(:params) { super().merge(title: nil) }

        it { expect { test_instance.validate_post_info!(params) }.not_to raise_error }
      end

      context 'when title is a valid string' do
        let(:params) { super().merge(title: 'My awesome video') }

        it { expect { test_instance.validate_post_info!(params) }.not_to raise_error }
      end

      context 'when title is not a string' do
        let(:messages) { { title: ['must be a String'] } }
        let(:params)   { super().merge(title: 1) }

        it_behaves_like 'RequestValidationError', :validate_post_info!
      end

      context 'when title exceeds maximum length' do
        let(:messages) { { title: ["must be less than #{described_class::MAX_TITLE_LENGTH} characters"] } }
        let(:params)   { super().merge(title: 'a' * (described_class::MAX_TITLE_LENGTH + 1)) }

        it_behaves_like 'RequestValidationError', :validate_post_info!
      end

      context 'when title is exactly at maximum length' do
        let(:params) { super().merge(title: 'a' * described_class::MAX_TITLE_LENGTH) }

        it { expect { test_instance.validate_post_info!(params) }.not_to raise_error }
      end
    end

    context 'with boolean fields validation' do
      let(:params) { { privacy_level: 'PUBLIC_TO_EVERYONE' } }

      context 'when all boolean fields are valid' do
        let(:params) do
          super().merge(
            disable_duet:         true,
            disable_stitch:       false,
            disable_comment:      true,
            brand_content_toggle: false,
            brand_organic_toggle: true,
            is_aigc:              false
          )
        end

        it { expect { test_instance.validate_post_info!(params) }.not_to raise_error }
      end

      context 'when boolean field is not a boolean' do
        let(:message) { ['must be a boolean (true or false)'] }

        %i[
          disable_duet
          disable_stitch
          disable_comment
          brand_content_toggle
          brand_organic_toggle
          is_aigc
        ].each do |field|
          context "when the #{field} is not a boolean" do
            let(:params)   { super().merge(field => :not_a_boolean) }
            let(:messages) { { field => message } }

            it_behaves_like 'RequestValidationError', :validate_post_info!
          end
        end
      end

      context 'when boolean field is missing' do
        it { expect { test_instance.validate_post_info!(params) }.not_to raise_error }
      end

      context 'when multiple boolean fields are invalid' do
        let(:messages) do
          {
            disable_duet:         ['must be a boolean (true or false)'],
            brand_content_toggle: ['must be a boolean (true or false)']
          }
        end

        let(:params) { super().merge(disable_duet: 'yes', brand_content_toggle: 1) }

        it_behaves_like 'RequestValidationError', :validate_post_info!
      end
    end

    context 'with video_cover_timestamp_ms validation' do
      let(:params) { { privacy_level: 'PUBLIC_TO_EVERYONE' } }

      context 'when timestamp is nil' do
        let(:params) { super().merge(video_cover_timestamp_ms: nil) }

        it { expect { test_instance.validate_post_info!(params) }.not_to raise_error }
      end

      context 'when timestamp is a valid non-negative integer' do
        let(:params) { super().merge(video_cover_timestamp_ms: 1_000) }

        it { expect { test_instance.validate_post_info!(params) }.not_to raise_error }
      end

      context 'when timestamp is negative' do
        let(:params)   { super().merge(video_cover_timestamp_ms: -1) }
        let(:messages) { { video_cover_timestamp_ms: ['must be a non-negative integer'] } }

        it_behaves_like 'RequestValidationError', :validate_post_info!
      end

      context 'when timestamp is not an integer' do
        let(:params)   { super().merge(video_cover_timestamp_ms: :not_a_integer) }
        let(:messages) { { video_cover_timestamp_ms: ['must be a non-negative integer'] } }

        it_behaves_like 'RequestValidationError', :validate_post_info!
      end
    end

    context 'with multiple validation errors' do
      let(:params) do
        {
          privacy_level:            'INVALID',
          title:                    2,
          disable_duet:             'not_boolean',
          video_cover_timestamp_ms: -1
        }
      end

      let(:messages) do
        {
          privacy_level:            [
            'must be one of: PUBLIC_TO_EVERYONE, MUTUAL_FOLLOW_FRIENDS, FOLLOWER_OF_CREATOR, SELF_ONLY'
          ],
          title:                    ['must be a String'],
          disable_duet:             ['must be a boolean (true or false)'],
          video_cover_timestamp_ms: ['must be a non-negative integer']
        }
      end

      it_behaves_like 'RequestValidationError', :validate_post_info!
    end

    context 'with all optional fields valid' do
      let(:params) do
        {
          privacy_level:            'PUBLIC_TO_EVERYONE',
          title:                    'Test video title',
          disable_duet:             true,
          disable_stitch:           false,
          disable_comment:          true,
          brand_content_toggle:     false,
          brand_organic_toggle:     true,
          is_aigc:                  false,
          video_cover_timestamp_ms: 1_000
        }
      end

      it { expect { test_instance.validate_post_info!(params) }.not_to raise_error }
    end
  end
end
