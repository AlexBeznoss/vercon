# frozen_string_literal: true

require 'spec_helper'
require 'vercon/claude'

RSpec.describe Vercon::Claude do
  let(:config) { instance_double(Vercon::Config, token: 'api_token', claude_model: 'claude-v1') }
  let(:client) { instance_double('HTTPX Client') }
  let(:response) { instance_double('HTTPX Response', json: {}) }

  subject(:claude) { described_class.new }

  before do
    allow(Vercon::Config).to receive(:new).and_return(config)
    allow(HTTPX).to receive(:plugin).and_return(client)
    allow(client).to receive(:with).and_return(client)
    allow(client).to receive(:post).and_return(response)
  end

  describe '#submit' do
    let(:model) { 'custom-model' }
    let(:system) { 'system prompt' }
    let(:max_tokens) { 100 }
    let(:temperature) { 0.5 }
    let(:stop_sequences) { %w[stop1 stop2] }
    let(:user) { 'user prompt' }
    let(:messages) { [{ role: 'user', content: 'message' }] }

    context 'with all parameters provided' do
      it 'sends a POST request with the correct parameters' do
        expect(client).to receive(:post).with(
          '/v1/messages',
          body: {
            model: model,
            system: system,
            max_tokens: max_tokens,
            temperature: temperature,
            stop_sequences: stop_sequences,
            messages: messages
          }.to_json
        ).and_return(response)

        claude.submit(
          model: model,
          system: system,
          max_tokens: max_tokens,
          temperature: temperature,
          stop_sequences: stop_sequences,
          messages: messages
        )
      end
    end

    context 'with missing optional parameters' do
      it 'sends a POST request with default values' do
        expect(client).to receive(:post).with(
          '/v1/messages',
          body: {
            model: config.claude_model,
            max_tokens: 4096,
            temperature: 0.2,
            messages: [{ role: 'user', content: user }]
          }.to_json
        ).and_return(response)

        claude.submit(user: user)
      end
    end

    context 'when the response contains an error' do
      let(:error_message) { 'An error occurred' }
      let(:error_response) { { 'type' => 'error', 'error' => { 'message' => error_message } } }

      before do
        allow(response).to receive(:json).and_return(error_response)
      end

      it 'returns the error message' do
        result = claude.submit(user: user)
        expect(result).to eq({ error: error_message })
      end
    end

    context 'when the response is successful' do
      let(:text) { 'Generated text' }
      let(:success_response) { { 'content' => [{ 'text' => text }] } }

      before do
        allow(response).to receive(:json).and_return(success_response)
      end

      it 'returns the generated text' do
        result = claude.submit(user: user)
        expect(result).to eq({ text: text })
      end
    end
  end
end
