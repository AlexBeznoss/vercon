# frozen_string_literal: true

module Vercon
  module Commands
    class Init < Dry::CLI::Command
      desc "Initialize vercon config"

      option :claude_token, desc: "Claude API token"
      option :claude_model, desc: "Claude model to use by default"
      option :open, type: :boolean, default: nil, desc: "Open generated test file by default"

      def initialize
        @stdout = Vercon::Stdout.new

        @config = Vercon::Config.new
        @config_existed = @config.exists?

        super
      end

      def call(**opts)
        setup_token(opts)
        setup_claude_model(opts)
        setup_default_open(opts)

        @stdout.ok("Config file #{@config_existed ? "updated" : "created"}!")
      end

      private

      def setup_token(opts)
        if @config.claude_token && @stdout.no?("Claude API token already set to `#{@config.claude_token}`. Do you want to replace it?")
          return
        end

        token = opts[:claude_token]
        token ||= @stdout.ask("Provide your Claude API token:")
        @config.claude_token = token
      end

      def setup_claude_model(opts)
        if @config.claude_model && @stdout.no?("Claude default model already set to `#{@config.claude_model}`. Do you want to replace it?")
          return
        end

        model = opts[:claude_model]
        model ||= @stdout.select("Select Claude model that will be used by default:", Vercon::Config::CLAUDE_MODELS,
          default: Vercon::Config::DEFAULT_CLAUDE_MODEL, cycle: true)
        @config.claude_model = model
      end

      def setup_default_open(opts)
        open = opts[:open]
        if open.nil?
          open = @stdout.select(
            "Open generated test file by default?",
            {Yes: true, No: false},
            default: "No",
            cycle: true
          )
        end

        @config.open_by_default = open
      end
    end
  end
end
