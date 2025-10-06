# frozen_string_literal: true

RSpec.describe Tiktok::Open::Sdk::HttpClient do
  let(:test_url)      { 'https://api.tiktok.com/test' }
  let(:http_response) { instance_double(Net::HTTPResponse, code: '200', body: '{"success": true}') }

  before { WebMock.allow_net_connect! }

  after  { WebMock.disable_net_connect! }

  describe 'class interface and module inclusion' do
    it { expect(described_class).to respond_to(:request) }
    it { expect(described_class::SUPPORTED_METHODS).to eq(%i[get post]) }
  end

  describe '.request' do
    let(:method)  { :get }
    let(:params)  { {} }
    let(:headers) { {} }
    let(:body)    { nil }

    before { allow(Net::HTTP).to receive(:new).and_return(instance_double(Net::HTTP, request: http_response)) }

    context 'when performing a GET request' do
      let(:method)        { :get }
      let(:http_instance) { instance_spy(Net::HTTP) }
      let(:result)        { described_class.request(method, test_url, params: params, headers: headers, body: body) }

      before do
        allow(Net::HTTP).to receive(:new).with('api.tiktok.com', 443).and_return(http_instance)
        allow(http_instance).to receive(:request).and_return(http_response)
      end

      context 'with a successful response' do
        before { result }

        it 'sets up the HTTP client and performs the GET request' do
          expect(http_instance).to have_received(:use_ssl=).with(true)
          expect(http_instance).to have_received(:read_timeout=).with(10)
          expect(http_instance).to have_received(:open_timeout=).with(5)
          expect(http_instance).to have_received(:request)
          expect(result).to eq(http_response)
        end
      end

      context 'with query parameters' do
        before do
          allow(Net::HTTP).to receive(:new).and_return(http_instance)

          described_class.request(method, test_url, params: { foo: 'bar', baz: 'qux' })
        end

        it 'correctly encodes and sends query parameters' do
          expect(http_instance).to have_received(:use_ssl=).with(true)
          expect(http_instance).to have_received(:read_timeout=).with(10)
          expect(http_instance).to have_received(:open_timeout=).with(5)
          expect(http_instance).to have_received(:request).with(kind_of(Net::HTTP::Get))
        end
      end

      context 'with a plain HTTP URL' do
        before do
          allow(Net::HTTP).to receive(:new).with('example.com', 80).and_return(http_instance)

          described_class.request(method, 'http://example.com/test')
        end

        it 'disables SSL and sets timeouts for HTTP requests' do
          expect(http_instance).to have_received(:use_ssl=).with(false)
          expect(http_instance).to have_received(:read_timeout=).with(10)
          expect(http_instance).to have_received(:open_timeout=).with(5)
          expect(http_instance).to have_received(:request)
        end
      end
    end

    context 'when performing a POST request' do
      let(:method)  { :post }
      let(:body)    { nil }
      let(:headers) { {} }

      let(:http_instance) { instance_spy(Net::HTTP) }

      before do
        allow(Net::HTTP).to receive(:new).and_return(http_instance)
        allow(http_instance).to receive(:request).and_return(http_response)
      end

      context 'with a basic POST and no body' do
        let!(:result) { described_class.request(method, test_url, params: params, headers: headers, body: body) }

        it 'sets up the HTTP client and performs the POST request' do
          expect(http_instance).to have_received(:use_ssl=).with(true)
          expect(http_instance).to have_received(:read_timeout=).with(10)
          expect(http_instance).to have_received(:open_timeout=).with(5)
          expect(http_instance).to have_received(:request).with(kind_of(Net::HTTP::Post))
          expect(result).to eq(http_response)
        end
      end

      context 'with form-encoded body' do
        let(:body)         { { name: 'test', value: '123' } }
        let(:headers)      { { 'Content-Type': 'application/x-www-form-urlencoded' } }
        let(:post_request) { instance_double(Net::HTTP::Post) }

        before do
          allow(Net::HTTP::Post).to receive(:new).and_return(post_request)
          allow(post_request).to receive(:set_form_data).with(body)
          allow(post_request).to receive(:body=)
          described_class.request(:post, test_url, headers: headers, body: body)
        end

        it { expect(http_instance).to have_received(:request) }
      end
    end

    context 'when an unsupported HTTP method is used' do
      subject(:result) { described_class.request(method, test_url) }

      let(:method) { :put }

      it { expect { result }.to raise_error(ArgumentError, 'Unsupported method: put') }
    end

    context 'when an unsupported content type is provided' do
      let(:http_instance) { instance_spy(Net::HTTP) }
      let(:body)          { { data: 'test' } }
      let(:headers)       { { 'Content-Type': 'text/plain' } }
      let(:request)       { described_class.request(:post, test_url, headers: headers, body: body) }

      context 'when the request is executed' do
        before { allow(Net::HTTP).to receive(:new).and_return(http_instance) }

        it 'raises ArgumentError and configures the HTTP client' do
          expect { request }.to raise_error(ArgumentError, 'Unsupported content type: text/plain')

          expect(http_instance).to have_received(:use_ssl=).with(true)
          expect(http_instance).to have_received(:read_timeout=).with(10)
          expect(http_instance).to have_received(:open_timeout=).with(5)
        end
      end
    end

    context 'when custom headers are provided' do
      let(:http_instance) { instance_spy(Net::HTTP) }
      let(:headers)       { { 'Authorization' => 'Bearer token', 'User-Agent' => 'TikTok-SDK' } }

      before do
        allow(Net::HTTP).to receive(:new).and_return(http_instance)
        allow(http_instance).to receive(:request).and_return(http_response)

        described_class.request(method, test_url, headers: headers)
      end

      it 'includes custom headers in the request' do
        expect(http_instance).to have_received(:use_ssl=).with(true)
        expect(http_instance).to have_received(:read_timeout=).with(10)
        expect(http_instance).to have_received(:open_timeout=).with(5)
        expect(http_instance).to have_received(:request)
      end
    end

    context 'when body is nil' do
      let(:http_instance) { instance_spy(Net::HTTP) }
      let(:method)        { :post }
      let(:body)          { nil }

      before do
        allow(Net::HTTP).to receive(:new).and_return(http_instance)
        allow(http_instance).to receive(:request).and_return(http_response)

        described_class.request(method, test_url, body: body)
      end

      it 'does not assign a body to the request' do
        expect(http_instance).to have_received(:use_ssl=).with(true)
        expect(http_instance).to have_received(:read_timeout=).with(10)
        expect(http_instance).to have_received(:open_timeout=).with(5)
        expect(http_instance).to have_received(:request).with(kind_of(Net::HTTP::Post))
      end
    end
  end

  describe '.get' do
    subject(:result) { described_class.get(test_url, params: params, headers: headers) }

    let(:params)  { {} }
    let(:headers) { {} }

    let(:request_params) { [:get, test_url, { params: params, headers: headers }] }

    before do
      allow(Net::HTTP).to receive(:new).and_return(instance_double(Net::HTTP, request: http_response))

      allow(described_class).to receive(:request).with(*request_params).and_return(http_response)
    end

    it { expect(result).to eq(http_response) }

    context 'when delegating to .request with GET method' do
      before { result }

      it { expect(described_class).to have_received(:request).with(*request_params) }
    end

    context 'when all parameters are provided' do
      let(:params)  { { query: 'param', filter: 'active' } }
      let(:headers) { { 'Authorization' => 'Bearer token', 'User-Agent' => 'TikTok-SDK' } }

      before { result }

      it { expect(described_class).to have_received(:request).with(*request_params) }
    end

    context 'when only URL is provided' do
      subject(:result) { described_class.get(test_url) }

      let(:request_params) { [:get, test_url, { params: {}, headers: {} }] }

      before { result }

      it { expect(described_class).to have_received(:request).with(*request_params) }
    end
  end

  describe '.post' do
    subject(:result) { described_class.post(test_url, params: params, headers: headers, body: body) }

    let(:params)  { {} }
    let(:headers) { {} }
    let(:body)    { nil }

    let(:request_params) { [:post, test_url, { params: params, headers: headers, body: body }] }

    before do
      allow(Net::HTTP).to receive(:new).and_return(instance_double(Net::HTTP, request: http_response))

      allow(described_class).to receive(:request).with(*request_params).and_return(http_response)
    end

    it { expect(result).to eq(http_response) }

    context 'when delegating to .request with POST method' do
      before { result }

      it { expect(described_class).to have_received(:request).with(*request_params) }
    end

    context 'when all parameters are provided' do
      let(:params)  { { query: 'param' } }
      let(:headers) { { 'Content-Type': 'application/json' } }
      let(:body)    { { data: 'test' } }

      before { result }

      it { expect(described_class).to have_received(:request).with(*request_params) }
    end
  end

  describe 'integration with Net::HTTP' do
    subject(:response) { described_class.request(:get, test_url) }

    let(:test_url) { 'https://httpbin.org/get' }

    before do
      stub_request(:get, test_url)
        .to_return(status:  200,
                   body:    '{"success": true}',
                   headers: { 'Content-Type': 'application/json' })
    end

    context 'when network is available' do
      before { WebMock.allow_net_connect! }

      it 'performs an actual HTTP request', :integration do
        expect(response).to be_a(Net::HTTPResponse)
        expect(response.code).to eq('200')
      end
    end
  end

  describe 'error handling' do
    context 'when the URL is invalid' do
      subject(:request) { described_class.request(:get, 'invalid_url') }

      it { expect { request }.to raise_error(ArgumentError, 'not an HTTP URI') }
    end

    context 'when a network timeout occurs' do
      before do
        allow(Net::HTTP).to receive(:new).and_return(
          instance_double(Net::HTTP).tap do |http|
            allow(http).to receive(:use_ssl=)
            allow(http).to receive(:read_timeout=)
            allow(http).to receive(:open_timeout=)
            allow(http).to receive(:request).and_raise(Timeout::Error, 'timeout')
          end
        )
      end

      it { expect { described_class.request(:get, test_url) }.to raise_error(Timeout::Error, 'timeout') }
    end
  end

  describe 'edge case handling' do
    let(:http_instance) { instance_spy(Net::HTTP) }

    before do
      allow(Net::HTTP).to receive(:new).and_return(http_instance)
      allow(http_instance).to receive(:request).and_return(http_response)

      described_class.request(:get, test_url, params: {})
    end

    context 'when params hash is empty' do
      it 'does not modify the URI query' do
        expect(http_instance).to have_received(:use_ssl=).with(true)
        expect(http_instance).to have_received(:read_timeout=).with(10)
        expect(http_instance).to have_received(:open_timeout=).with(5)
        expect(http_instance).to have_received(:request)
      end
    end

    context 'when headers hash is empty' do
      it 'handles empty headers without error' do
        expect(http_instance).to have_received(:use_ssl=).with(true)
        expect(http_instance).to have_received(:read_timeout=).with(10)
        expect(http_instance).to have_received(:open_timeout=).with(5)
        expect(http_instance).to have_received(:request)
      end
    end

    context 'when query parameters contain special characters' do
      let(:params) { { 'key with spaces' => 'value with spaces', 'special&chars' => 'test=value' } }

      it 'encodes complex parameters correctly' do
        expect(http_instance).to have_received(:use_ssl=).with(true)
        expect(http_instance).to have_received(:read_timeout=).with(10)
        expect(http_instance).to have_received(:open_timeout=).with(5)
        expect(http_instance).to have_received(:request)
      end
    end
  end
end
