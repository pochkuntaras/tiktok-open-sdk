# frozen_string_literal: true

RSpec.describe Tiktok::Open::Sdk::OpenApi::Auth::Client do
  let(:client_key)    { 'dummy_client_key' }
  let(:client_secret) { 'dummy_client_secret' }
  let(:token_url)     { 'https://example.com/oauth/token/' }

  before do
    Tiktok::Open::Sdk.configure do |config|
      config.client_key          = client_key
      config.client_secret       = client_secret
      config.user_auth.token_url = token_url
    end
  end

  describe '.fetch_client_token' do
    subject(:result) { described_class.fetch_client_token }

    let(:success_response_body) do
      {
        access_token: 'dummy_access_token',
        expires_in:   7200,
        token_type:   'Bearer'
      }.to_json
    end

    let(:error_response_body) do
      {
        error:             'invalid_client',
        error_description: 'Client info is illegal or malformed.',
        log_id:            'dummy_log_id'
      }.to_json
    end

    let(:body) do
      {
        client_key:    client_key,
        client_secret: client_secret,
        grant_type:    'client_credentials'
      }
    end

    let(:headers) do
      {
        'Content-Type':  'application/x-www-form-urlencoded',
        'Cache-Control': 'no-cache'
      }
    end

    context 'when the request is successful' do
      let(:expected_response) do
        {
          success:  true,
          code:     200,
          response: {
            access_token: 'dummy_access_token',
            expires_in:   7200,
            token_type:   'Bearer'
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

      it { is_expected.to eq(expected_response) }

      context 'when verifying the HTTP request' do
        before { result }

        it 'makes a POST request to the correct token URL' do
          expect(WebMock).to have_requested(:post, token_url)
            .with(headers: headers, body: body)
        end

        it 'includes the correct grant_type in the request body' do
          expect(WebMock).to have_requested(:post, token_url)
            .with(body: hash_including(grant_type: 'client_credentials'))
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

    context 'when the client credentials are invalid' do
      let(:expected_response) do
        {
          success:  false,
          code:     400,
          response: {
            error:             'invalid_client',
            error_description: 'Client info is illegal or malformed.',
            log_id:            'dummy_log_id'
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
            body:    error_response_body,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it { is_expected.to eq(expected_response) }

      context 'when verifying the HTTP request' do
        before { result }

        it 'makes a POST request to the token URL' do
          expect(WebMock).to have_requested(:post, token_url)
            .with(headers: headers, body: body)
        end
      end
    end

    context 'when the server returns a 500 internal server error' do
      let(:expected_response) do
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

      it { is_expected.to eq(expected_response) }
    end

    context 'when the response contains invalid JSON' do
      let(:expected_response) do
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

      it { is_expected.to eq(expected_response) }
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

    context 'when using different client credentials' do
      subject(:result) { described_class.fetch_client_token }

      let(:client_key)    { 'another_client_key' }
      let(:client_secret) { 'another_client_secret' }

      let(:body) do
        {
          client_key:    client_key,
          client_secret: client_secret,
          grant_type:    'client_credentials'
        }
      end

      before do
        Tiktok::Open::Sdk.configure do |config|
          config.client_key    = client_key
          config.client_secret = client_secret
        end

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

      it { expect(result).to a_hash_including(success: true, code: 200) }

      context 'when verifying the HTTP request uses the provided credentials' do
        before { result }

        it { expect(WebMock).to have_requested(:post, token_url).with(headers: headers, body: body) }
      end
    end

    context 'when the client_key is nil' do
      let(:client_key)        { nil }
      let(:body_with_nil_key) { body.merge(client_key: nil) }

      let(:expected_response) do
        {
          success:  true,
          code:     200,
          response: {
            error:             'invalid_request',
            error_description: 'The request parameters are malformed.',
            log_id:            'dummy_log_id'
          }
        }
      end

      before do
        stub_request(:post, token_url)
          .with(
            headers: headers,
            body:    body_with_nil_key
          )
          .to_return(
            status: 200,
            body:   error_response_body
          )
      end

      it { expect(result).to a_hash_including(success: true, code: 200) }

      context 'when verifying the client_key in the request body is nil' do
        let(:request_params) { { headers: headers, body: body_with_nil_key } }

        before { result }

        it { expect(WebMock).to have_requested(:post, token_url).with(request_params) }
      end
    end
  end
end
