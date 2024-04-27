# frozen_string_literal: true

require "httpx"

module Vercon
  class Claude
    BASE_URL = "https://api.anthropic.com"

    def initialize
      config = Vercon::Config.new

      @api_token = config.claude_token
      @claude_model = config.claude_model
    end

    def submit(model: nil, system: nil, max_tokens: 4096, temperature: 0.2, stop_sequences: nil, user: nil, # rubocop:disable Metrics/ParameterLists
      messages: nil, tools: nil)
      body = {
        model: model || @claude_model,
        system: system,
        max_tokens: max_tokens,
        temperature: temperature,
        stop_sequences: stop_sequences,
        messages: messages || [{role: "user", content: user}],
        tools: tools
      }.reject { |_, v| v.nil? || ["", [], {}].include?(v) }

      client.post("/v1/messages", body: body.to_json).then { |res| prepare_response(res.json) }
    end

    private

    def extra_headers
      {"x-api-key" => @api_token, "anthropic-version" => "2023-06-01"}
    end

    def client
      @client ||=
        HTTPX
          .plugin(:retries)
          .with(headers: {"Content-Type" => "application/json", "Cache-Control" => "no-cache",
                          "anthropic-version" => "2023-06-01", "anthropic-beta" => "tools-2024-04-04"})
          .with(headers: extra_headers)
          .with(origin: BASE_URL)
          .with(ssl: {alpn_protocols: %w[http/1.1]})
          .with(
            timeout: {
              connect_timeout: 10,
              read_timeout: 400,
              keep_alive_timeout: 480,
              request_timeout: 400,
              operation_timeout: 400
            }
          )
    end

    def prepare_response(response)
      return {error: response.dig("error", "message")} if response["type"] == "error"

      texts = []
      tools = []

      response["content"].each do |msg|
        case msg["type"]
        when "text"
          texts << msg["text"].gsub(%r{\n?</?thinking>\n?}, "")
        when "tool_use"
          tools << msg.slice("name", "id", "input").transform_keys(&:to_sym)
        end
      end

      {text: texts.join("\n"), tools: tools}
    end
  end
end
