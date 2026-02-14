# frozen_string_literal: true

RSpec.describe Tiktok::Open::Sdk::Helpers::Validators::SourceInfoValidator do
  let(:test_class) do
    Class.new do
      include Tiktok::Open::Sdk::Helpers::Validators::SourceInfoValidator
    end
  end

  let(:test_instance) { test_class.new }

  describe '#validate_source_info!' do
    context 'when source_info is not a hash' do
      let(:params)   { [] }
      let(:messages) { { source_info: ['must be a Hash'] } }

      it_behaves_like 'RequestValidationError', :validate_source_info!
    end

    context 'with source' do
      let(:messages) { { source: ['must be one of: PULL_FROM_URL, FILE_UPLOAD'] } }

      context 'when source is missing' do
        let(:params) { {} }

        it_behaves_like 'RequestValidationError', :validate_source_info!
      end

      context 'when source is invalid' do
        let(:params) { { source: 'INVALID_SOURCE' } }

        it_behaves_like 'RequestValidationError', :validate_source_info!
      end
    end

    context 'with PULL_FROM_URL source' do
      let(:params)   { { source: 'PULL_FROM_URL' } }
      let(:messages) { { video_url: ['is required and must be a non-empty string for PULL_FROM_URL'] } }

      context 'when valid' do
        let(:params) { super().merge(video_url: 'https://example.com/video.mp4') }

        it { expect { test_instance.validate_source_info!(params) }.not_to raise_error }
      end

      context 'when video_url is missing' do
        it_behaves_like 'RequestValidationError', :validate_source_info!
      end

      context 'when video_url is empty' do
        let(:params) { super().merge(video_url: '') }

        it_behaves_like 'RequestValidationError', :validate_source_info!
      end

      context 'when video_url is not a string' do
        let(:params) { super().merge(video_url: :invalid_type) }

        it_behaves_like 'RequestValidationError', :validate_source_info!
      end
    end

    context 'with FILE_UPLOAD source' do
      let(:params) { { source: 'FILE_UPLOAD', video_size: 10_485_760 } }

      context 'with valid params' do
        context 'when valid with required fields only' do
          it { expect { test_instance.validate_source_info!(params) }.not_to raise_error }
        end

        context 'when valid with all optional fields' do
          let(:params) { super().merge(chunk_size: 1_048_576, total_chunk_count: 10) }

          it { expect { test_instance.validate_source_info!(params) }.not_to raise_error }
        end
      end

      context 'with video_size' do
        let(:messages) { { video_size: ['is required and must be a positive integer for FILE_UPLOAD'] } }

        context 'when video_size is missing' do
          let(:params) { { source: 'FILE_UPLOAD' } }

          it_behaves_like 'RequestValidationError', :validate_source_info!
        end

        context 'when video_size is zero' do
          let(:params) { super().merge(video_size: 0) }

          it_behaves_like 'RequestValidationError', :validate_source_info!
        end

        context 'when video_size is negative' do
          let(:params) { super().merge(video_size: -100) }

          it_behaves_like 'RequestValidationError', :validate_source_info!
        end

        context 'when video_size is not an integer' do
          let(:params) { super().merge(video_size: :invalid_type) }

          it_behaves_like 'RequestValidationError', :validate_source_info!
        end
      end

      context 'with chunk_size' do
        let(:messages) { { chunk_size: ['must be a positive integer if provided'] } }

        context 'when chunk_size is zero' do
          let(:params) { super().merge(chunk_size: 0) }

          it_behaves_like 'RequestValidationError', :validate_source_info!
        end

        context 'when chunk_size is negative' do
          let(:params) { super().merge(chunk_size: -1) }

          it_behaves_like 'RequestValidationError', :validate_source_info!
        end

        context 'when chunk_size is not an integer' do
          let(:params) { super().merge(chunk_size: :invalid_type) }

          it_behaves_like 'RequestValidationError', :validate_source_info!
        end
      end

      context 'with total_chunk_count' do
        let(:messages) { { total_chunk_count: ['must be a positive integer if provided'] } }

        context 'when total_chunk_count is zero' do
          let(:params) { super().merge(total_chunk_count: 0) }

          it_behaves_like 'RequestValidationError', :validate_source_info!
        end

        context 'when total_chunk_count is negative' do
          let(:params) { super().merge(total_chunk_count: -1) }

          it_behaves_like 'RequestValidationError', :validate_source_info!
        end

        context 'when total_chunk_count is not an integer' do
          let(:params) { super().merge(total_chunk_count: :invalid_type) }

          it_behaves_like 'RequestValidationError', :validate_source_info!
        end
      end

      context 'with multiple validation errors' do
        let(:messages) do
          {
            video_size:        ['is required and must be a positive integer for FILE_UPLOAD'],
            chunk_size:        ['must be a positive integer if provided'],
            total_chunk_count: ['must be a positive integer if provided']
          }
        end

        let(:params) do
          {
            source:            'FILE_UPLOAD',
            video_size:        0,
            chunk_size:        -1,
            total_chunk_count: 'invalid'
          }
        end

        it_behaves_like 'RequestValidationError', :validate_source_info!
      end
    end
  end
end
