# frozen_string_literal: true

module Vercon
  module Commands
    class Init < Dry::CLI::Command
      desc 'Initialize vercon config'

      option :token, desc: 'Claude API token'
      option :claude_model, desc: 'Claude model to use by default'

      def initialize
        @stdout = Vercon::Stdout.new

        @config = Vercon::Config.new
        @config_existed = @config.exists?

        super
      end

      def call(**opts)
        token_changed = setup_token(opts)
        claude_changed = setup_claude_model(opts)

        if token_changed || claude_changed
          @stdout.ok("Config file #{@config_existed ? 'updated' : 'created'}!")
        else
          @stdout.warn('Config file is not touched.')
        end
      end

      private

      def setup_token(opts)
        if @config.token && @stdout.no?("Claude API token already set to `#{@config.token}`. Do you want to replace it?")
          return
        end

        token = opts[:token]
        token ||= @stdout.ask('Provide your Claude API token:')
        @config.token = token
      end

      def setup_claude_model(opts)
        if @config.claude_model && @stdout.no?("Claude default model already set to `#{@config.claude_model}`. Do you want to replace it?")
          return
        end

        model = opts[:claude_model]
        model ||= @stdout.select('Select Claude model that will be used by default:', Vercon::Config::CLAUDE_MODELS,
                                 default: Vercon::Config::DEFAULT_CLAUDE_MODEL, cycle: true)
        @config.claude_model = model
      end
    end
  end
end
