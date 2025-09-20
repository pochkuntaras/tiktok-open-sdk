# frozen_string_literal: true

require 'spec_helper'
require 'webmock/rspec'

RSpec.describe Tiktok::Open::Sdk::OpenApi::User do
  let(:client_key)    { 'dummy_client_key' }
  let(:client_secret) { 'dummy_client_secret' }
  let(:access_token)  { 'valid_access_token_12345' }
  let(:fields)        { %w[open_id union_id avatar_url] }
  let(:user_info_url) { 'https://open.tiktokapis.com/v2/user/info/' }

  before do
    Tiktok::Open::Sdk.configure do |config|
      config.client_key    = client_key
      config.client_secret = client_secret
      config.user_info_url = user_info_url
    end

    WebMock.disable_net_connect!
  end

  after { WebMock.allow_net_connect! }

  describe '#get_user_info' do
    context 'when the request is successful' do
      subject(:request) { described_class.get_user_info(access_token: access_token, fields: fields) }

      let(:response) do
        {
          data:  {
            user: {
              open_id:    'TwyXyL92boeRLas33rxKoNAXqwg9x0i000-',
              union_id:   'a277c13dc4ac-5f89-8865-eb15-59390905',
              avatar_url: 'https://p16-sign-va.tiktokcdn.com/tos-maliva-avt-0068/' \
                          '8502945187138401952~tplv-tiktokx-cropcenter:168:168.jpeg'
            }
          },
          error: {
            code:    'ok',
            message: '',
            log_id:  '20250918235835142E10CDA3DCEF12CA3B'
          }
        }.to_json
      end

      before do
        stub_request(:get, user_info_url)
          .with(
            query:   { fields: fields.join(',') },
            headers: { 'Authorization' => "Bearer #{access_token}" }
          )
          .to_return(
            status:  200,
            body:    response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it { is_expected.to eq(success: true, code: 200, response: response) }
    end

    context 'when fields parameter is missing' do
      subject(:request) { described_class.get_user_info(access_token: access_token, fields: [], validate: false) }

      let(:response) do
        {
          data:  {},
          error: {
            code:    'invalid_params',
            message: 'Fields is required, please provide fields in the request',
            log_id:  '6F8A0BF05F038518295052798D78D57852'
          }
        }
      end

      before do
        stub_request(:get, user_info_url)
          .with(
            query:   { fields: '' },
            headers: { 'Authorization' => "Bearer #{access_token}" }
          )
          .to_return(
            status:  400,
            body:    response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it { is_expected.to eq(success: false, code: 400, response: response) }
    end

    context 'when access token is invalid' do
      subject(:request) do
        described_class.get_user_info(
          access_token: 'invalid_token',
          fields:       fields,
          validate:     false
        )
      end

      let(:response) do
        {
          data:  {},
          error: {
            code:    'access_token_invalid',
            message: 'The access token is invalid or not found in the request.',
            log_id:  '20250920002050100115989EF4EE2405DD'
          }
        }
      end

      before do
        stub_request(:get, user_info_url)
          .with(
            query:   { fields: fields.join(',') },
            headers: { 'Authorization' => 'Bearer invalid_token' }
          )
          .to_return(
            status:  401,
            body:    response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it { is_expected.to eq(success: false, code: 401, response: response) }
    end

    context 'when validation is enabled' do
      subject(:request) { described_class.get_user_info(access_token: access_token, fields: fields) }

      context 'with invalid access token' do
        let(:access_token)  { 'short' }
        let(:error_message) { 'Invalid token format: must be at least 10 printable characters.' }

        it { expect { request }.to raise_error(Tiktok::Open::Sdk::RequestValidationError, error_message) }
      end

      context 'with invalid fields' do
        let(:fields)        { %w[open_id non_existent_field another_invalid_field] }
        let(:error_message) { 'Invalid fields: non_existent_field, another_invalid_field' }

        it { expect { request }.to raise_error(Tiktok::Open::Sdk::RequestValidationError, error_message) }
      end
    end

    context 'when validation is disabled' do
      subject(:request) do
        described_class.get_user_info(
          access_token: access_token,
          fields:       invalid_fields,
          validate:     false
        )
      end

      let(:invalid_fields) { %w[open_id non_existent_field] }

      let(:response) do
        {
          data:  {},
          error: {
            code:    'invalid_params',
            message: 'Invalid field(s): non_existent_field',
            log_id:  '6F8A0BF05F0798D78D5785238518295052'
          }
        }
      end

      before do
        stub_request(:get, user_info_url)
          .with(
            query:   { fields: invalid_fields.join(',') },
            headers: { 'Authorization' => "Bearer #{access_token}" }
          )
          .to_return(
            status:  400,
            body:    response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it { is_expected.to eq(success: false, code: 400, response: response) }
    end

    context 'when network error occurs' do
      subject(:request) { described_class.get_user_info(access_token: access_token, fields: fields) }

      before do
        stub_request(:get, user_info_url)
          .with(
            query:   { fields: fields.join(',') },
            headers: { 'Authorization' => "Bearer #{access_token}" }
          )
          .to_timeout
      end

      it { expect { request }.to raise_error(Timeout::Error) }
    end

    context 'with all available fields' do
      subject(:request) { described_class.get_user_info(access_token: access_token, fields: fields) }

      let(:fields) do
        %w[
          open_id union_id avatar_url avatar_url_100 avatar_large_url
          display_name bio_description profile_deep_link is_verified
          username follower_count following_count likes_count video_count
        ]
      end

      # rubocop:disable Naming/VariableNumber
      let(:response) do
        {
          data:  {
            user: {
              open_id:           '-000i0x9gbo29LyXWyTXAN0oKxrwq33asLRe',
              union_id:          '50909395-15be-5688-98f5-ca4cd31c772a',
              avatar_url:        'https://example.com/avatar.jpg',
              avatar_url_100:    'https://example.com/avatar_100.jpg',
              avatar_large_url:  'https://example.com/avatar_large.jpg',
              display_name:      'Test User',
              bio_description:   'This is a test bio',
              profile_deep_link: 'https://www.tiktok.com/@username',
              is_verified:       false,
              username:          'testuser',
              follower_count:    1000,
              following_count:   500,
              likes_count:       5000,
              video_count:       20
            }
          },
          error: {
            code:    'ok',
            message: '',
            log_id:  '3BCAD3E01E2415358328915025EF12CA3B'
          }
        }.to_json
      end
      # rubocop:enable Naming/VariableNumber

      before do
        stub_request(:get, user_info_url)
          .with(
            query:   { fields: fields.join(',') },
            headers: { 'Authorization' => "Bearer #{access_token}" }
          )
          .to_return(
            status:  200,
            body:    response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it { is_expected.to eq(success: true, code: 200, response: response) }
    end

    context 'with non-JSON response' do
      subject(:request) { described_class.get_user_info(access_token: access_token, fields: fields) }

      let(:body)     { '<html><body>Internal Server Error</body></html>' }
      let(:response) { { raw: body } }

      before do
        stub_request(:get, user_info_url)
          .with(
            query:   { fields: fields.join(',') },
            headers: { 'Authorization' => "Bearer #{access_token}" }
          )
          .to_return(
            status:  500,
            body:    body,
            headers: { 'Content-Type' => 'text/html' }
          )
      end

      it { is_expected.to eq(success: false, code: 500, response: response) }
    end
  end
end
