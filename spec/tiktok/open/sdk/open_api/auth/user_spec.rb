# frozen_string_literal: true

RSpec.describe Tiktok::Open::Sdk::OpenApi::Auth::User do
  let(:client_key)         { 'test_client_key_123' }
  let(:client_secret)      { 'test_client_secret_456' }
  let(:auth_url)           { 'https://www.tiktok.com/v2/auth/authorize/' }
  let(:token_url)          { 'https://open.tiktokapis.com/v2/oauth/token/' }
  let(:scopes)             { %w[user.info.basic user.info.profile] }
  let(:redirect_uri)       { 'https://example.com/callback' }
  let(:authorization_code) { 'test_auth_code_789' }

  let(:query_params) { URI.decode_www_form(result.query).to_h }

  before do
    Tiktok::Open::Sdk.configure do |config|
      config.client_key             = client_key
      config.client_secret          = client_secret
      config.user_auth.auth_url     = auth_url
      config.user_auth.token_url    = token_url
      config.user_auth.scopes       = scopes
      config.user_auth.redirect_uri = redirect_uri
    end
  end

  describe '.authorization_uri' do
    context 'when called with no parameters' do
      let(:result) { described_class.authorization_uri }

      it { expect(result).to be_a(URI::HTTPS) }
      it { expect(result.to_s).to start_with(auth_url) }
      it { expect(query_params['client_key']).to eq(client_key) }
      it { expect(query_params['response_type']).to eq('code') }
      it { expect(query_params['scope']).to eq(scopes.join(',')) }
      it { expect(query_params['redirect_uri']).to eq(redirect_uri) }
      it { expect(query_params['state']).to eq('') }
    end

    context 'when called with custom scope' do
      let(:scope) { %w[user.info.basic] }
      let(:result) { described_class.authorization_uri(scope: scope) }

      it { expect(query_params['scope']).to eq(scope.join(',')) }
      it { expect(query_params['client_key']).to eq(client_key) }
      it { expect(query_params['response_type']).to eq('code') }
      it { expect(query_params['redirect_uri']).to eq(redirect_uri) }
      it { expect(query_params['state']).to eq('') }
    end

    context 'when called with custom redirect_uri' do
      let(:redirect_uri) { 'https://custom.example.com/callback' }
      let(:result) { described_class.authorization_uri(redirect_uri: redirect_uri) }

      it { expect(query_params['redirect_uri']).to eq(redirect_uri) }
      it { expect(query_params['client_key']).to eq(client_key) }
      it { expect(query_params['response_type']).to eq('code') }
      it { expect(query_params['scope']).to eq(scopes.join(',')) }
      it { expect(query_params['state']).to eq('') }
    end

    context 'when called with custom state' do
      let(:state) { 'random_state_string' }
      let(:result) { described_class.authorization_uri(state: state) }

      it { expect(query_params['state']).to eq(state) }
      it { expect(query_params['client_key']).to eq(client_key) }
      it { expect(query_params['response_type']).to eq('code') }
      it { expect(query_params['scope']).to eq(scopes.join(',')) }
      it { expect(query_params['redirect_uri']).to eq(redirect_uri) }
    end

    context 'when called with multiple custom parameters' do
      let(:params) do
        {
          scope:        %w[user.info.basic],
          redirect_uri: 'https://multi.example.com/callback',
          state:        'multi_param_state'
        }
      end

      let(:result) { described_class.authorization_uri(params) }

      it { expect(query_params['scope']).to eq(params[:scope].join(',')) }
      it { expect(query_params['redirect_uri']).to eq(params[:redirect_uri]) }
      it { expect(query_params['state']).to eq(params[:state]) }
      it { expect(query_params['client_key']).to eq(client_key) }
      it { expect(query_params['response_type']).to eq('code') }
    end

    context 'when called with empty scope array' do
      let(:result) { described_class.authorization_uri(scope: []) }

      it { expect(query_params['scope']).to be_nil }
    end

    context 'when called with nil parameters' do
      let(:result) { described_class.authorization_uri(scope: nil, redirect_uri: nil, state: nil) }

      it { expect(query_params['scope']).to eq('') }
      it { expect(query_params['redirect_uri']).to eq('') }
      it { expect(query_params['state']).to eq('') }
    end

    context 'when configuration has empty scopes' do
      let(:result) { described_class.authorization_uri }

      before { Tiktok::Open::Sdk.configure { |config| config.user_auth.scopes = [] } }

      it { expect(query_params['scope']).to eq('') }
    end

    context 'when configuration has nil redirect_uri' do
      let(:result) { described_class.authorization_uri }

      before { Tiktok::Open::Sdk.configure { |config| config.user_auth.redirect_uri = nil } }

      it { expect(query_params['redirect_uri']).to eq('') }
    end
  end

  describe '.fetch_access_token' do
    subject(:result) { described_class.fetch_access_token(code: authorization_code) }

    let(:success_response_body) do
      {
        access_token:       'act.test_access_token_d60341ec2b987fa5',
        expires_in:         86_400,
        open_id:            'test_open_id_1234567890',
        refresh_expires_in: 31_536_000,
        refresh_token:      'rft.test_refresh_token_d60341ec2b987fa5',
        scope:              'user.info.basic',
        token_type:         'Bearer'
      }.to_json
    end

    let(:error_response_body) do
      {
        error:             'invalid_grant',
        error_description: 'Authorization code is expired.',
        log_id:            'test_log_id_d60341ec2b987fa5'
      }.to_json
    end

    let(:body) do
      {
        client_key:    client_key,
        client_secret: client_secret,
        code:          authorization_code,
        grant_type:    'authorization_code',
        redirect_uri:  redirect_uri
      }
    end

    let(:headers) do
      {
        'Content-Type':  'application/x-www-form-urlencoded',
        'Cache-Control': 'no-cache'
      }
    end

    context 'when the request is successful' do
      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  200,
            body:    success_response_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      context 'when the response is successful with parsed token data' do
        let(:response) do
          {
            success:  true,
            code:     200,
            response: {
              access_token:       'act.test_access_token_d60341ec2b987fa5',
              expires_in:         86_400,
              open_id:            'test_open_id_1234567890',
              refresh_expires_in: 31_536_000,
              refresh_token:      'rft.test_refresh_token_d60341ec2b987fa5',
              scope:              'user.info.basic',
              token_type:         'Bearer'
            }
          }
        end

        it { is_expected.to eq(response) }
      end

      context 'when the HTTP request is correct' do
        before { result }

        it { expect(WebMock).to have_requested(:post, token_url).with(headers: headers, body: body) }
      end
    end

    context 'when the authorization code is expired' do
      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  400,
            body:    error_response_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      context 'when the response is failed with parsed error data' do
        let(:response) do
          {
            success:  false,
            code:     400,
            response: {
              error:             'invalid_grant',
              error_description: 'Authorization code is expired.',
              log_id:            'test_log_id_d60341ec2b987fa5'
            }
          }
        end

        it { is_expected.to eq(response) }
      end
    end

    context 'when using a custom redirect_uri' do
      subject(:result) do
        described_class.fetch_access_token(
          code:         authorization_code,
          redirect_uri: custom_redirect_uri
        )
      end

      let(:custom_redirect_uri) { 'https://custom.example.com/callback' }
      let(:custom_request_body) { body.merge(redirect_uri: custom_redirect_uri) }

      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    custom_request_body
          )
          .to_return(
            status:  200,
            body:    success_response_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { expect(result[:success]).to be(true) }

      context 'when verifying the HTTP request' do
        before { result }

        it 'uses the custom redirect_uri in the request' do
          expect(WebMock).to have_requested(:post, token_url)
            .with(headers: headers, body: custom_request_body)
        end
      end
    end

    context 'when the response contains invalid JSON' do
      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  200,
            body:    'invalid json response',
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to include(success: true, code: 200, response: { raw: 'invalid json response' }) }
    end

    context 'when there is a network error' do
      before { stub_request(:post, token_url).with(headers: headers, body: body).to_timeout }

      it { expect { result }.to raise_error(Timeout::Error) }
    end

    context 'when the server returns a 500 error' do
      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  500,
            body:    'Internal Server Error',
            headers: { 'Content-Type': 'text/plain' }
          )
      end

      it { is_expected.to include(success: false, code: 500, response: { raw: 'Internal Server Error' }) }
    end

    context 'when the server returns a 401 unauthorized error' do
      let(:unauthorized_response_body) do
        {
          error:             'invalid_client',
          error_description: 'Client authentication failed.',
          log_id:            'test_log_id_unauthorized_1234567890'
        }.to_json
      end

      let(:response) do
        {
          success:  false,
          code:     401,
          response: {
            error:             'invalid_client',
            error_description: 'Client authentication failed.',
            log_id:            'test_log_id_unauthorized_1234567890'
          }
        }
      end

      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  401,
            body:    unauthorized_response_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { expect(result).to include(response) }
    end
  end

  describe '.refresh_access_token' do
    subject(:result) { described_class.refresh_access_token(refresh_token: refresh_token) }

    let(:refresh_token) { 'rft.test_refresh_token_d60341ec2b987fa5' }

    let(:success_response_body) do
      {
        access_token:       'act.test_access_token_d60341ec2b987fa5',
        expires_in:         86_400,
        open_id:            'test_open_id_1234567890',
        refresh_expires_in: 31_528_708,
        refresh_token:      'rft.test_new_refresh_token_d60341ec2b987fa5',
        scope:              'user.info.basic',
        token_type:         'Bearer'
      }.to_json
    end

    let(:invalid_request_error_body) do
      {
        error:             'invalid_request',
        error_description: 'The request parameters are malformed.',
        log_id:            '202206221854370101130062072500FFA2'
      }.to_json
    end

    let(:invalid_grant_error_body) do
      {
        error:             'invalid_grant',
        error_description: 'Refresh token is invalid or expired.',
        log_id:            '2025090712305321A45C357B1409A149B8'
      }.to_json
    end

    let(:body) do
      {
        client_key:    client_key,
        client_secret: client_secret,
        grant_type:    'refresh_token',
        refresh_token: refresh_token
      }
    end

    let(:headers) do
      {
        'Content-Type':  'application/x-www-form-urlencoded',
        'Cache-Control': 'no-cache'
      }
    end

    context 'when the request is successful' do
      let(:response) do
        {
          success:  true,
          code:     200,
          response: {
            access_token:       'act.test_access_token_d60341ec2b987fa5',
            expires_in:         86_400,
            open_id:            'test_open_id_1234567890',
            refresh_expires_in: 31_528_708,
            refresh_token:      'rft.test_new_refresh_token_d60341ec2b987fa5',
            scope:              'user.info.basic',
            token_type:         'Bearer'
          }
        }
      end

      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  200,
            body:    success_response_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to eq(response) }

      context 'when verifying the HTTP request' do
        before { result }

        it 'makes a POST request to the correct token URL' do
          expect(WebMock).to have_requested(:post, token_url)
            .with(headers: headers, body: body)
        end

        it 'includes the correct grant_type in the request body' do
          expect(WebMock).to have_requested(:post, token_url)
            .with(body: hash_including(grant_type: 'refresh_token'))
        end

        it 'includes the refresh_token in the request body' do
          expect(WebMock).to have_requested(:post, token_url)
            .with(body: hash_including(refresh_token: refresh_token))
        end

        it 'includes client credentials in the request body' do
          expect(WebMock).to have_requested(:post, token_url)
            .with(body: hash_including(
              client_key:    client_key,
              client_secret: client_secret
            ))
        end

        it 'sets the correct content type header' do
          expect(WebMock).to have_requested(:post, token_url)
            .with(headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })
        end

        it 'sets the cache control header' do
          expect(WebMock).to have_requested(:post, token_url)
            .with(headers: { 'Cache-Control' => 'no-cache' })
        end
      end
    end

    context 'when the request parameters are malformed' do
      let(:response) do
        {
          success:  false,
          code:     400,
          response: {
            error:             'invalid_request',
            error_description: 'The request parameters are malformed.',
            log_id:            '202206221854370101130062072500FFA2'
          }
        }
      end

      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  400,
            body:    invalid_request_error_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to eq(response) }
    end

    context 'when the server returns a 401 unauthorized error' do
      let(:unauthorized_response_body) do
        {
          error:             'invalid_client',
          error_description: 'Client authentication failed.',
          log_id:            'test_log_id_unauthorized_refresh_1234567890'
        }.to_json
      end

      let(:response) do
        {
          success:  false,
          code:     401,
          response: {
            error:             'invalid_client',
            error_description: 'Client authentication failed.',
            log_id:            'test_log_id_unauthorized_refresh_1234567890'
          }
        }
      end

      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  401,
            body:    unauthorized_response_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to eq(response) }
    end

    context 'when the server returns a 500 internal server error' do
      let(:response) do
        {
          success:  false,
          code:     500,
          response: { raw: 'Internal Server Error' }
        }
      end

      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  500,
            body:    'Internal Server Error',
            headers: { 'Content-Type': 'text/plain' }
          )
      end

      it { is_expected.to eq(response) }
    end

    context 'when the response contains invalid JSON' do
      let(:response) do
        {
          success:  true,
          code:     200,
          response: { raw: 'invalid json response' }
        }
      end

      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  200,
            body:    'invalid json response',
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to eq(response) }
    end

    context 'when there is a network timeout' do
      before { stub_request(:post, token_url).with(headers: headers, body: body).to_timeout }

      it { expect { result }.to raise_error(Timeout::Error) }
    end

    context 'when there is a network connection error' do
      before do
        stub_request(:post, token_url)
          .with(headers: headers, body: body)
          .to_raise(SocketError.new('Connection refused'))
      end

      it { expect { result }.to raise_error(SocketError, 'Connection refused') }
    end

    context 'when using different refresh tokens' do
      subject(:result) { described_class.refresh_access_token(refresh_token: different_refresh_token) }

      let(:different_refresh_token) { 'rft.different_refresh_token_abcdef1234567890' }
      let(:different_body) { body.merge(refresh_token: different_refresh_token) }

      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    different_body
          )
          .to_return(
            status:  200,
            body:    success_response_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { expect(result).to a_hash_including(success: true, code: 200) }

      context 'when the provided refresh token uses in the request' do
        before { result }

        it { expect(WebMock).to have_requested(:post, token_url).with(headers: headers, body: different_body) }
      end
    end

    context 'when the refresh token is nil' do
      let(:refresh_token) { nil }
      let(:body_with_nil_token) { body.merge(refresh_token: nil) }

      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    body_with_nil_token
          )
          .to_return(
            status:  400,
            body:    invalid_request_error_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { expect(result).to a_hash_including(success: false, code: 400) }

      context 'when the refresh_token in the request body is nil' do
        before { result }

        it { expect(WebMock).to have_requested(:post, token_url).with(headers: headers, body: body_with_nil_token) }
      end
    end

    context 'when the refresh token is an empty string' do
      let(:refresh_token) { '' }
      let(:body_with_empty_token) { body.merge(refresh_token: '') }

      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    body_with_empty_token
          )
          .to_return(
            status:  400,
            body:    invalid_grant_error_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { expect(result).to a_hash_including(success: false, code: 400) }

      context 'when the refresh_token in the request body is empty' do
        before { result }

        it { expect(WebMock).to have_requested(:post, token_url).with(headers: headers, body: body_with_empty_token) }
      end
    end
  end

  describe '.revoke_access_token' do
    subject(:result) { described_class.revoke_access_token(token: token) }

    let(:token)                 { 'rft.test_refresh_token_d60341ec2b987fa5' }
    let(:revoke_token_url)      { 'https://open.tiktokapis.com/v2/oauth/revoke/' }
    let(:success_response_body) { '{}' }

    let(:error_response_body) do
      {
        error:             'invalid_grant',
        error_description: 'Access token is invalid or expired.',
        log_id:            '20250915234824C5043283223F5C0B9DC4'
      }.to_json
    end

    let(:body) do
      {
        client_key:    client_key,
        client_secret: client_secret,
        token:         token
      }
    end

    let(:headers) do
      {
        'Content-Type':  'application/x-www-form-urlencoded',
        'Cache-Control': 'no-cache'
      }
    end

    before do
      Tiktok::Open::Sdk.configure do |config|
        config.user_auth.revoke_token_url = revoke_token_url
      end
    end

    context 'when the request is successful' do
      let(:response) do
        {
          success:  true,
          code:     200,
          response: {}
        }
      end

      before do
        stub_request(:post, revoke_token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  200,
            body:    success_response_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to eq(response) }

      context 'when verifying the HTTP request' do
        before { result }

        it 'makes a POST request to the correct revoke token URL' do
          expect(WebMock).to have_requested(:post, revoke_token_url)
            .with(headers: headers, body: body)
        end

        it 'includes the token in the request body' do
          expect(WebMock).to have_requested(:post, revoke_token_url)
            .with(body: hash_including(token: token))
        end

        it 'includes client credentials in the request body' do
          expect(WebMock).to have_requested(:post, revoke_token_url)
            .with(body: hash_including(
              client_key:    client_key,
              client_secret: client_secret
            ))
        end

        it 'sets the correct content type header' do
          expect(WebMock).to have_requested(:post, revoke_token_url)
            .with(headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })
        end

        it 'sets the cache control header' do
          expect(WebMock).to have_requested(:post, revoke_token_url)
            .with(headers: { 'Cache-Control' => 'no-cache' })
        end
      end
    end

    context 'when the token is invalid or expired' do
      let(:response) do
        {
          success:  true,
          code:     200,
          response: {
            error:             'invalid_grant',
            error_description: 'Access token is invalid or expired.',
            log_id:            '20250915234824C5043283223F5C0B9DC4'
          }
        }
      end

      before do
        stub_request(:post, revoke_token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  200,
            body:    error_response_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to eq(response) }

      context 'when verifying the HTTP request' do
        before { result }

        it 'makes a POST request to the revoke token URL' do
          expect(WebMock).to have_requested(:post, revoke_token_url)
            .with(headers: headers, body: body)
        end
      end
    end

    context 'when the server returns a 400 bad request error' do
      let(:bad_request_response_body) do
        {
          error:             'invalid_request',
          error_description: 'The request parameters are malformed.',
          log_id:            '20250915234824C5043283223F5C0B9DC4'
        }.to_json
      end

      let(:response) do
        {
          success:  false,
          code:     400,
          response: {
            error:             'invalid_request',
            error_description: 'The request parameters are malformed.',
            log_id:            '20250915234824C5043283223F5C0B9DC4'
          }
        }
      end

      before do
        stub_request(:post, revoke_token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  400,
            body:    bad_request_response_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to eq(response) }
    end

    context 'when the server returns a 401 unauthorized error' do
      let(:unauthorized_response_body) do
        {
          error:             'invalid_client',
          error_description: 'Client authentication failed.',
          log_id:            '20250915234824C5043283223F5C0B9DC4'
        }.to_json
      end

      let(:response) do
        {
          success:  false,
          code:     401,
          response: {
            error:             'invalid_client',
            error_description: 'Client authentication failed.',
            log_id:            '20250915234824C5043283223F5C0B9DC4'
          }
        }
      end

      before do
        stub_request(:post, revoke_token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  401,
            body:    unauthorized_response_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to eq(response) }
    end

    context 'when the server returns a 500 internal server error' do
      let(:response) do
        {
          success:  false,
          code:     500,
          response: { raw: 'Internal Server Error' }
        }
      end

      before do
        stub_request(:post, revoke_token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  500,
            body:    'Internal Server Error',
            headers: { 'Content-Type': 'text/plain' }
          )
      end

      it { is_expected.to eq(response) }
    end

    context 'when the response contains invalid JSON' do
      let(:response) do
        {
          success:  true,
          code:     200,
          response: { raw: 'invalid json response' }
        }
      end

      before do
        stub_request(:post, revoke_token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  200,
            body:    'invalid json response',
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to eq(response) }
    end

    context 'when there is a network timeout' do
      before { stub_request(:post, revoke_token_url).with(headers: headers, body: body).to_timeout }

      it { expect { result }.to raise_error(Timeout::Error) }
    end

    context 'when there is a network connection error' do
      before do
        stub_request(:post, revoke_token_url)
          .with(headers: headers, body: body)
          .to_raise(SocketError.new('Connection refused'))
      end

      it { expect { result }.to raise_error(SocketError, 'Connection refused') }
    end

    context 'when using different tokens' do
      subject(:result) { described_class.revoke_access_token(token: different_token) }

      let(:different_token) { 'rft.different_token_abcdef1234567890' }
      let(:different_body) { body.merge(token: different_token) }

      before do
        stub_request(:post, revoke_token_url)
          .with(
            headers: headers,
            body:    different_body
          )
          .to_return(
            status:  200,
            body:    success_response_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { expect(result).to a_hash_including(success: true, code: 200) }

      context 'when verifying the HTTP request uses the provided token' do
        before { result }

        it { expect(WebMock).to have_requested(:post, revoke_token_url).with(headers: headers, body: different_body) }
      end
    end

    context 'when the token is nil' do
      let(:token) { nil }
      let(:body)  { super().merge(token: nil) }

      let(:response) do
        {
          success:  false,
          code:     400,
          response: {
            error:             'invalid_request',
            error_description: 'The request parameters are malformed.',
            log_id:            '20250915234824C5043283223F5C0B9DC4'
          }
        }
      end

      before do
        stub_request(:post, revoke_token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  400,
            body:    {
              error:             'invalid_request',
              error_description: 'The request parameters are malformed.',
              log_id:            '20250915234824C5043283223F5C0B9DC4'
            }.to_json,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { expect(result).to a_hash_including(success: false, code: 400) }

      context 'when verifying the token in the request body is nil' do
        let(:request_params) { { headers: headers, body: body } }

        before { result }

        it { expect(WebMock).to have_requested(:post, revoke_token_url).with(request_params) }
      end
    end

    context 'when the token is an empty string' do
      let(:token) { '' }
      let(:body)  { super().merge(token: '') }

      let(:response) do
        {
          success:  true,
          code:     200,
          response: {
            error:             'invalid_grant',
            error_description: 'Access token is invalid or expired.',
            log_id:            '20250915234824C5043283223F5C0B9DC4'
          }
        }
      end

      before do
        stub_request(:post, revoke_token_url)
          .with(
            headers: headers,
            body:    body
          )
          .to_return(
            status:  200,
            body:    error_response_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { expect(result).to a_hash_including(success: true, code: 200) }

      context 'when verifying the token in the request body is empty' do
        let(:request_params) { { headers: headers, body: body } }

        before { result }

        it { expect(WebMock).to have_requested(:post, revoke_token_url).with(request_params) }
      end
    end
  end
end
