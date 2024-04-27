# frozen_string_literal: true

require "spec_helper"
require "vercon/claude"

RSpec.describe Vercon::Claude do
  let(:config) { instance_double(Vercon::Config, claude_token: "api_token", claude_model: "claude-v1") }
  let(:client) { instance_double("HTTPX Client") }
  let(:response) { instance_double("HTTPX Response", json: {"content" => []}) }

  subject(:claude) { described_class.new }

  before do
    allow(Vercon::Config).to receive(:new).and_return(config)
    allow(HTTPX).to receive(:plugin).and_return(client)
    allow(client).to receive(:with).and_return(client)
    allow(client).to receive(:post).and_return(response)
  end

  describe "#submit" do
    let(:model) { "custom-model" }
    let(:system) { "system prompt" }
    let(:max_tokens) { 100 }
    let(:temperature) { 0.5 }
    let(:stop_sequences) { %w[stop1 stop2] }
    let(:user) { "user prompt" }
    let(:messages) { [{role: "user", content: "message"}] }
    let(:tools) { [{name: "tool1", description: "Tool 1"}] }

    context "with all parameters provided" do
      it "sends a POST request with the correct parameters" do
        expect(client).to receive(:post).with(
          "/v1/messages",
          body: {
            model: model,
            system: system,
            max_tokens: max_tokens,
            temperature: temperature,
            stop_sequences: stop_sequences,
            messages: messages,
            tools: tools
          }.to_json
        ).and_return(response)

        claude.submit(
          model: model,
          system: system,
          max_tokens: max_tokens,
          temperature: temperature,
          stop_sequences: stop_sequences,
          messages: messages,
          tools: tools
        )
      end
    end

    context "with missing optional parameters" do
      it "sends a POST request with default values" do
        expect(client).to receive(:post).with(
          "/v1/messages",
          body: {
            model: config.claude_model,
            max_tokens: 4096,
            temperature: 0.2,
            messages: [{role: "user", content: user}]
          }.to_json
        ).and_return(response)

        claude.submit(user: user)
      end
    end

    context "when the response contains an error" do
      let(:error_message) { "An error occurred" }
      let(:error_response) { {"type" => "error", "error" => {"message" => error_message}} }

      before do
        allow(response).to receive(:json).and_return(error_response)
      end

      it "returns the error message" do
        result = claude.submit(user: user)
        expect(result).to eq({error: error_message})
      end
    end

    context "when the response is successful with text content" do
      let(:text) { "Generated text" }
      let(:success_response) { {"content" => [{"type" => "text", "text" => text}]} }

      before do
        allow(response).to receive(:json).and_return(success_response)
      end

      it "returns the generated text" do
        result = claude.submit(user: user)
        expect(result).to eq({text: text, tools: []})
      end
    end

    context "when the response is successful with tool use content" do
      let(:tool_use) { {"type" => "tool_use", "name" => "tool1", "id" => "1", "input" => "input"} }
      let(:success_response) { {"content" => [tool_use]} }

      before do
        allow(response).to receive(:json).and_return(success_response)
      end

      it "returns the tool use information" do
        result = claude.submit(user: user)
        expect(result).to eq({text: "", tools: [{name: "tool1", id: "1", input: "input"}]})
      end
    end

    context "when the response contains thinking tags" do
      let(:text_with_tags) { "<thinking>Generated text</thinking>" }
      let(:success_response) { {"content" => [{"type" => "text", "text" => text_with_tags}]} }

      before do
        allow(response).to receive(:json).and_return(success_response)
      end

      it "removes the thinking tags from the generated text" do
        result = claude.submit(user: user)
        expect(result).to eq({text: "Generated text", tools: []})
      end
    end
  end

  describe "#extra_headers" do
    it "returns the extra headers with the API token and Anthropic version" do
      headers = claude.send(:extra_headers)
      expect(headers).to eq({"x-api-key" => config.claude_token, "anthropic-version" => "2023-06-01"})
    end
  end

  describe "#client" do
    it "configures the HTTPX client with the correct settings" do
      expect(HTTPX).to receive(:plugin).with(:retries).and_return(client)
      expect(client).to receive(:with).with(
        headers: {
          "Content-Type" => "application/json",
          "Cache-Control" => "no-cache",
          "anthropic-version" => "2023-06-01",
          "anthropic-beta" => "tools-2024-04-04"
        }
      ).and_return(client)
      expect(client).to receive(:with).with(headers: claude.send(:extra_headers)).and_return(client)
      expect(client).to receive(:with).with(origin: described_class::BASE_URL).and_return(client)
      expect(client).to receive(:with).with(ssl: {alpn_protocols: %w[http/1.1]}).and_return(client)
      expect(client).to receive(:with).with(
        timeout: {
          connect_timeout: 10,
          read_timeout: 400,
          keep_alive_timeout: 480,
          request_timeout: 400,
          operation_timeout: 400
        }
      ).and_return(client)

      claude.send(:client)
    end
  end
end
