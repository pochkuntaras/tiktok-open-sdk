# frozen_string_literal: true

# rubocop:disable RSpec/SubjectStub

RSpec.describe Tiktok::Open::Omniauth::Strategies::TiktokOpenSdk do
  subject(:strategy) do
    described_class.new(app, client_key, client_secret).tap do |strategy|
      allow(strategy).to receive(:request).and_return(request)
    end
  end

  let(:app)           { ->(_env) { [200, {}, ['Hello']] } }
  let(:client_key)    { 'test_client_key' }
  let(:client_secret) { 'test_client_secret' }

  let(:request) do
    instance_double(
      Rack::Request,
      params:  {},
      session: {},
      scheme:  'https',
      url:     'https://example.com/callback'
    )
  end

  let(:redirect_uri)  { 'https://example.com/auth/tiktok_open_sdk/callback' }
  let(:auth_url)      { 'https://www.tiktok.com/v2/auth/authorize/' }
  let(:token_url)     { 'https://open.tiktokapis.com/v2/oauth/token/' }
  let(:user_info_url) { 'https://open.tiktokapis.com/v2/user/info/' }
  let(:scopes)        { %w[user.info.basic user.info.profile] }
  let(:code)          { 'test_auth_code' }
  let(:access_token)  { 'test_access_token' }
  let(:refresh_token) { 'test_refresh_token' }
  let(:expires_in)    { 86_400 }
  let(:open_id)       { 'test_open_id' }

  before do
    OmniAuth.config.test_mode = true
    WebMock.disable_net_connect!
  end

  after do
    OmniAuth.config.test_mode = false
    WebMock.allow_net_connect!
  end

  describe 'client options' do
    it { expect(strategy.options.client_options.site).to eq(Tiktok::Open::Sdk::Config::OPEN_API_BASE_URL) }
    it { expect(strategy.options.client_options.authorize_url).to eq(auth_url) }
    it { expect(strategy.options.client_options.token_url).to eq(token_url) }
    it { expect(strategy.options.client_options.auth_scheme).to eq(:request_body) }
    it { expect(strategy.options.client_options.auth_token_class).to eq(described_class::AccessToken) }
  end

  describe '#authorize_params' do
    it { expect(strategy.authorize_params[:client_key]).to eq(client_key) }
    it { expect(strategy.authorize_params[:scope]).to eq(scopes.join(',')) }
    it { expect(strategy.authorize_params[:redirect_uri]).to eq(redirect_uri) }
  end

  describe '#request_phase' do
    let(:url) { strategy.authorize_url }

    it { expect { strategy.request_phase }.not_to raise_error }
  end

  describe '#uid' do
    let(:access_token_instance) { instance_double(described_class::AccessToken, token: access_token) }

    let(:user_info_response) do
      {
        success:  true,
        code:     200,
        response: {
          data: {
            user: {
              open_id:        open_id,
              display_name:   'Test User',
              avatar_url_100: 'https://example.com/avatar.jpg'
            }
          }
        }
      }
    end

    let(:method_messages) do
      {
        access_token:     access_token_instance,
        request_scopes:   %w[user.info.basic],
        user_info_fields: %w[open_id display_name avatar_url_100]
      }
    end

    before do
      allow(strategy).to receive_messages(method_messages)
      allow(Tiktok::Open::Sdk.user).to receive(:get_user_info).and_return(user_info_response)
    end

    it { expect(strategy.uid).to eq(open_id) }
  end

  describe '#info' do
    let(:access_token_instance) { instance_double(described_class::AccessToken, token: access_token) }

    let(:user_info_response) do
      {
        success:  true,
        code:     200,
        response: {
          data: {
            user: {
              open_id:        open_id,
              display_name:   'Test User',
              avatar_url_100: 'https://example.com/avatar.jpg'
            }
          }
        }
      }
    end

    let(:method_messages) do
      {
        access_token:     access_token_instance,
        request_scopes:   %w[user.info.basic],
        user_info_fields: %w[open_id display_name avatar_url_100]
      }
    end

    before do
      allow(strategy).to receive_messages(method_messages)
      allow(Tiktok::Open::Sdk.user).to receive(:get_user_info).and_return(user_info_response)
    end

    context 'with basic scope' do
      before { allow(request).to receive(:params).and_return('scopes' => 'user.info.basic') }

      it { expect(strategy.info).to eq(name: 'Test User', image: 'https://example.com/avatar.jpg') }
    end

    context 'with profile scope' do
      let(:user_info_response_with_profile) do
        {
          success:  true,
          code:     200,
          response: {
            data: {
              user: {
                open_id:           open_id,
                display_name:      'Test User',
                avatar_url_100:    'https://example.com/avatar.jpg',
                username:          'testuser',
                bio_description:   'Test bio',
                profile_deep_link: 'https://www.tiktok.com/@testuser'
              }
            }
          }
        }
      end

      let(:method_messages) do
        {
          access_token:     access_token_instance,
          request_scopes:   %w[user.info.basic user.info.profile],
          user_info_fields: %w[open_id display_name avatar_url_100 username bio_description profile_deep_link]
        }
      end

      before do
        allow(request).to receive(:params).and_return('scopes' => 'user.info.basic,user.info.profile')
        allow(strategy).to receive_messages(method_messages)
        allow(Tiktok::Open::Sdk.user).to receive(:get_user_info).and_return(user_info_response_with_profile)
      end

      it 'returns extended user info' do
        expect(strategy.info).to eq(
          name:              'Test User',
          image:             'https://example.com/avatar.jpg',
          username:          'testuser',
          bio_description:   'Test bio',
          profile_deep_link: 'https://www.tiktok.com/@testuser'
        )
      end
    end
  end

  describe '#extra' do
    let(:access_token_instance) { instance_double(described_class::AccessToken, token: access_token) }

    let(:user_data) do
      {
        open_id:        open_id,
        display_name:   'Test User',
        avatar_url_100: 'https://example.com/avatar.jpg'
      }
    end

    let(:user_info_response) do
      {
        success:  true,
        code:     200,
        response: {
          data: {
            user: user_data
          }
        }
      }
    end

    let(:method_messages) do
      {
        access_token:     access_token_instance,
        request_scopes:   %w[user.info.basic],
        user_info_fields: %w[open_id display_name avatar_url_100]
      }
    end

    before do
      allow(strategy).to receive_messages(method_messages)
      allow(Tiktok::Open::Sdk.user).to receive(:get_user_info).and_return(user_info_response)
    end

    it { expect(strategy.extra).to eq(user_data) }
  end
end

# rubocop:enable RSpec/SubjectStub
