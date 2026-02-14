# frozen_string_literal: true

RSpec.describe Tiktok::Open::Sdk::OpenApi::Post::Publish do
  let(:access_token)           { 'act.test_access_token_d60341ec2b987fa5_valid' }
  let(:creator_info_query_url) { 'https://open.tiktokapis.com/v2/post/publish/creator_info/query/' }
  let(:video_init_url)         { 'https://open.tiktokapis.com/v2/post/publish/video/init/' }

  before do
    Tiktok::Open::Sdk.configure do |config|
      config.creator_info_query_url = creator_info_query_url
      config.video_init_url         = video_init_url
    end
  end

  describe '.creator_info_query' do
    subject(:result) { described_class.creator_info_query(access_token: access_token) }

    let(:response) do
      {
        data:  {
          stitch_disabled:             false,
          comment_disabled:            false,
          creator_avatar_url:          'https://example.com/avatar.webp',
          creator_nickname:            'Test User',
          creator_username:            'testuser',
          duet_disabled:               false,
          max_video_post_duration_sec: 3600,
          privacy_level_options:       %w[PUBLIC_TO_EVERYONE MUTUAL_FOLLOW_FRIENDS SELF_ONLY]
        },
        error: {
          code:    'ok',
          message: '',
          log_id:  '202509250116218F87494797037D986BB5'
        }
      }
    end

    let(:headers) { { Authorization: "Bearer #{access_token}" } }

    context 'when the request is successful' do
      before do
        stub_request(:post, creator_info_query_url)
          .with(headers: headers)
          .to_return(
            status:  200,
            body:    response.to_json,
            headers: { 'Content-Type': 'application/json' }
          )

        allow(described_class).to receive(:validate_token!)
      end

      it { is_expected.to eq(success: true, code: 200, response: response) }

      context 'when verifying the HTTP request' do
        before { result }

        it { expect(described_class).to have_received(:validate_token!) }
        it { expect(WebMock).to have_requested(:post, creator_info_query_url).with(headers: headers) }
        it { expect(WebMock).to have_requested(:post, creator_info_query_url).with(body: nil) }
      end
    end

    context 'when the access token is invalid' do
      let(:response) do
        {
          error: {
            code:    'access_token_invalid',
            message: 'The access token is invalid or not found in the request.',
            log_id:  '20250924172335777F851BC590080C70AC'
          },
          data:  {}
        }
      end

      before do
        stub_request(:post, creator_info_query_url)
          .with(headers: headers)
          .to_return(
            status:  401,
            body:    response.to_json,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to eq(success: false, code: 401, response: response) }
    end

    context 'when the server returns a 500 internal server error' do
      before do
        stub_request(:post, creator_info_query_url)
          .with(headers: headers)
          .to_return(
            status:  500,
            body:    'Internal Server Error',
            headers: { 'Content-Type': 'text/plain' }
          )
      end

      it { is_expected.to eq(success: false, code: 500, response: { raw: 'Internal Server Error' }) }
    end

    context 'when there is a network timeout' do
      before { stub_request(:post, creator_info_query_url).with(headers: headers).to_timeout }

      it { expect { result }.to raise_error(Timeout::Error) }
    end

    context 'when there is a network connection error' do
      before do
        stub_request(:post, creator_info_query_url)
          .with(headers: headers)
          .to_raise(SocketError.new('Connection refused'))
      end

      it { expect { result }.to raise_error(SocketError, 'Connection refused') }
    end
  end

  describe '.video_init' do
    subject(:result) { described_class.video_init(access_token: access_token, params: params) }

    let(:params) do
      {
        post_info:   {
          title:                    'My first video #tiktok',
          privacy_level:            'SELF_ONLY',
          disable_duet:             false,
          disable_comment:          false,
          disable_stitch:           false,
          video_cover_timestamp_ms: 1000
        },
        source_info: {
          source:            'FILE_UPLOAD',
          video_type:        'video/mp4',
          video_size:        7_340_032,
          chunk_size:        7_340_032,
          total_chunk_count: 1
        }
      }
    end

    let(:video_init_success_response) do
      {
        data:  {
          publish_id: 'v_pub_file~v2-1.0000000000000000000',
          upload_url: 'https://open-upload-va.tiktokapis.com/upload?upload_id=2222222222222222222&' \
                      'upload_token=5106b2d3-ce75-508b-6b23-93d8cd264976'
        },
        error: {
          code:    'ok',
          message: '',
          log_id:  '2026021503555555555555555555555555'
        }
      }
    end

    let(:headers) do
      {
        Authorization:  "Bearer #{access_token}",
        'Content-Type': 'application/json; charset=UTF-8'
      }
    end

    context 'when the request is successful' do
      before do
        stub_request(:post, video_init_url)
          .with(headers: headers, body: params.to_json)
          .to_return(
            status:  200,
            body:    video_init_success_response.to_json,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to eq(success: true, code: 200, response: video_init_success_response) }
    end

    context 'when the API returns 403 (e.g. url_ownership_unverified)' do
      let(:params) do
        {
          post_info:   {
            title:                    'this will be a funny #cat video',
            privacy_level:            'SELF_ONLY',
            disable_duet:             false,
            disable_comment:          true,
            disable_stitch:           false,
            video_cover_timestamp_ms: 1000
          },
          source_info: {
            source:    'PULL_FROM_URL',
            video_url: 'https://example.verified.domain.com/example_video.mp4'
          }
        }
      end

      let(:error_response) do
        {
          error: {
            code:    'url_ownership_unverified',
            message: 'Please review our URL ownership verification rules at ' \
                     'https://developers.tiktok.com/doc/content-posting-api-media-transfer-guide/#pull_from_url',
            log_id:  '2026021504444444444444444444444444'
          }
        }
      end

      before do
        stub_request(:post, video_init_url)
          .with(headers: headers, body: params.to_json)
          .to_return(
            status:  403,
            body:    error_response.to_json,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to eq(success: false, code: 403, response: error_response) }
    end

    context 'when the access token is invalid' do
      let(:error_response) do
        {
          error: {
            code:    'access_token_invalid',
            message: 'The access token is invalid or not found in the request.',
            log_id:  '2025092411111111111111111111111111'
          },
          data:  {}
        }
      end

      before do
        stub_request(:post, video_init_url)
          .with(headers: headers, body: params.to_json)
          .to_return(
            status:  401,
            body:    error_response.to_json,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to eq(success: false, code: 401, response: error_response) }
    end

    context 'when the server returns a 500 internal server error' do
      before do
        stub_request(:post, video_init_url)
          .with(headers: headers, body: params.to_json)
          .to_return(
            status:  500,
            body:    'Internal Server Error',
            headers: { 'Content-Type': 'text/plain' }
          )
      end

      it { is_expected.to eq(success: false, code: 500, response: { raw: 'Internal Server Error' }) }
    end

    context 'when there is a network timeout' do
      before { stub_request(:post, video_init_url).with(headers: headers, body: params.to_json).to_timeout }

      it { expect { result }.to raise_error(Timeout::Error) }
    end

    context 'when there is a network connection error' do
      before do
        stub_request(:post, video_init_url)
          .with(headers: headers, body: params.to_json)
          .to_raise(SocketError.new('Connection refused'))
      end

      it { expect { result }.to raise_error(SocketError, 'Connection refused') }
    end

    context 'when the access token fails validation' do
      subject(:result) { described_class.video_init(access_token: invalid_token, params: params) }

      let(:invalid_token) { 'short' }

      let(:error_response) do
        [
          Tiktok::Open::Sdk::RequestValidationError,
          'Invalid token format: must be at least 10 printable characters.'
        ]
      end

      it { expect { result }.to raise_error(*error_response) }
      it { expect(WebMock).not_to have_requested(:post, video_init_url) }
    end

    context 'when params fail validation' do
      let(:params) { { post_info: nil, source_info: nil } }

      it { expect { result }.to raise_error(Tiktok::Open::Sdk::RequestValidationError) }
      it { expect(WebMock).not_to have_requested(:post, video_init_url) }
    end
  end
end
