# frozen_string_literal: true

RSpec.describe Tiktok::Open::Sdk::Helpers::Validators::TokenValidator do
  let(:test_class) do
    Class.new do
      include Tiktok::Open::Sdk::Helpers::Validators::TokenValidator
    end
  end

  let(:test_instance) { test_class.new }

  let(:valid_tokens) do
    [
      'valid_token_123',
      'another_valid_token',
      '1234567890',
      'ABCDEFGHIJKLMNOP',
      'token with spaces',
      'special!@#$%^&*()'
    ]
  end

  let(:invalid_inputs) { [nil, 123, [], {}, :symbol, Object.new] }
  let(:short_tokens)   { %w[a ab abc abcdefghi] }
  let(:invalid_tokens) { %W[token\x00null token\x01control token\x7fdelete token\x1bescape] }

  describe '#valid_token?' do
    context 'when input is a valid string token' do
      it { valid_tokens.each { |token| expect(test_instance.valid_token?(token)).to be(true) } }
    end

    context 'when input is not a string' do
      it { invalid_inputs.each { |input| expect(test_instance.valid_token?(input)).to be(false) } }
    end

    context 'when input is an empty string' do
      it { expect(test_instance.valid_token?('')).to be(false) }
      it { expect(test_instance.valid_token?('   ')).to be(false) }
    end

    context 'when token is too short' do
      it { short_tokens.each { |token| expect(test_instance.valid_token?(token)).to be(false) } }
    end

    context 'when token contains non-printable characters' do
      it { invalid_tokens.each { |token| expect(test_instance.valid_token?(token)).to be false } }
    end
  end

  describe '#validate_token!' do
    context 'with valid tokens' do
      it 'does not raise an error for valid tokens' do
        valid_tokens.each do |token|
          expect { test_instance.validate_token!(token) }
            .not_to raise_error, "Expected '#{token}' not to raise error"
        end
      end

      it { expect(test_instance.validate_token!('valid_token_123')).to be_nil }
    end

    context 'with invalid tokens' do
      let(:error_klass)   { Tiktok::Open::Sdk::RequestValidationError }
      let(:error_message) { 'Invalid token format: must be at least 10 printable characters.' }

      it 'raises RequestValidationError for non-string inputs' do
        invalid_inputs.each do |input|
          expect { test_instance.validate_token!(input) }.to raise_error(error_klass, error_message)
        end
      end

      it 'raises RequestValidationError for empty strings' do
        expect { test_instance.validate_token!('') }.to raise_error(error_klass, error_message)
      end

      it 'raises RequestValidationError for tokens that are too short' do
        short_tokens.each do |token|
          expect { test_instance.validate_token!(token) }.to raise_error(error_klass, error_message)
        end
      end

      it 'raises RequestValidationError for tokens with non-printable characters' do
        invalid_tokens.each do |token|
          expect { test_instance.validate_token!(token) }.to raise_error(error_klass, error_message)
        end
      end
    end
  end
end
