# frozen_string_literal: true

RSpec.describe Tiktok::Open::Sdk::Helpers::Validators::PostPublishValidator do
  subject(:test_instance) { test_class.new }

  let(:test_class) do
    Class.new do
      include Tiktok::Open::Sdk::Helpers::Validators::PostPublishValidator
    end
  end

  let(:validators) { Tiktok::Open::Sdk::Helpers::Validators }

  it { expect(described_class.included_modules).to include(validators::PostInfoValidator) }
  it { expect(described_class.included_modules).to include(validators::SourceInfoValidator) }

  it { is_expected.to respond_to(:validate_post_info!) }
  it { is_expected.to respond_to(:validate_source_info!) }

  context 'with errors' do
    let(:params) do
      {
        source_info: { source: 'INVALID_SOURCE' },
        post_info:   { privacy_level: 'INVALID_LEVEL' }
      }
    end

    let(:messages) do
      {
        post_info:   {
          privacy_level: [
            'must be one of: PUBLIC_TO_EVERYONE, MUTUAL_FOLLOW_FRIENDS, FOLLOWER_OF_CREATOR, SELF_ONLY'
          ]
        },
        source_info: {
          source: [
            'must be one of: PULL_FROM_URL, FILE_UPLOAD'
          ]
        }
      }
    end

    it_behaves_like 'RequestValidationError', :validate_video_init_info!
  end

  context 'with all fields valid' do
    let(:params) do
      {
        source_info: { source: 'FILE_UPLOAD', video_size: 10_485_760 },
        post_info:   { privacy_level: 'PUBLIC_TO_EVERYONE' }
      }
    end

    it { expect { test_instance.validate_video_init_info!(params) }.not_to raise_error }
  end
end
