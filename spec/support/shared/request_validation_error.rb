# frozen_string_literal: true

shared_examples 'RequestValidationError' do |method|
  subject(:validation) { test_class.new.public_send(method, params) }

  let(:error_class) { Tiktok::Open::Sdk::RequestValidationError }

  it { expect { validation }.to raise_error(error_class) { |e| expect(e.messages).to eq(messages) } }
end
