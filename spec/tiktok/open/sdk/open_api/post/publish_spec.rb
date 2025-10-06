# frozen_string_literal: true

RSpec.describe Tiktok::Open::Sdk::OpenApi::Post::Publish do
  let(:access_token)           { 'act.test_access_token_d60341ec2b987fa5_valid' }
  let(:creator_info_query_url) { 'https://open.tiktokapis.com/v2/post/publish/creator_info/query/' }

  before do
    Tiktok::Open::Sdk.configure do |config|
      config.creator_info_query_url = creator_info_query_url
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
end
