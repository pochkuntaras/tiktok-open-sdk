# frozen_string_literal: true

require 'securerandom'

RSpec.describe Tiktok::Open::Sdk do
  it { expect(described_class::VERSION).to be('0.2.0') }

  it { described_class.config { |c| expect(c).to eq(described_class) } }

  describe 'configuration' do
    describe 'setting the client_key' do
      let(:client_key) { SecureRandom.hex(9) }

      before do
        allow(described_class).to receive(:client_key=)

        described_class.client_key = client_key
      end

      it { expect(described_class).to have_received(:client_key=).with(client_key) }
    end

    describe 'setting the client_secret' do
      let(:client_secret) { SecureRandom.hex(16) }

      before do
        allow(described_class).to receive(:client_secret=)

        described_class.client_secret = client_secret
      end

      it { expect(described_class).to have_received(:client_secret=).with(client_secret) }
    end
  end

  describe '.user_auth' do
    it { expect(described_class.user_auth).to eq(Tiktok::Open::Sdk::OpenApi::Auth::User) }

    context 'when calling authorization_uri via user_auth' do
      let(:uri) { 'https://example.com/auth' }

      before { allow(described_class::OpenApi::Auth::User).to receive(:authorization_uri).and_return(uri) }

      it { expect(described_class.user_auth.authorization_uri).to eq(uri) }
    end

    context 'when comparing user_auth and direct module access' do
      let(:uri) { URI('https://test.com/auth') }

      before { allow(described_class::OpenApi::Auth::User).to receive(:authorization_uri).and_return(uri) }

      it 'returns the same result for both access patterns' do
        expect(described_class.user_auth.authorization_uri).to eq(uri)
        expect(described_class::OpenApi::Auth::User.authorization_uri).to eq(uri)
      end
    end
  end
end
