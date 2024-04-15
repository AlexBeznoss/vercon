# frozen_string_literal: true

require 'prism'
require 'dry/files'
require 'tty-spinner'
require 'tty-pager'
require 'tty-editor'

module Vercon
  module Commands
    class Generate < Dry::CLI::Command
      desc 'Generate test file'

      argument :path, desc: 'Path to the ruby file'

      option :edit_prompt, type: :boolean, default: false, aliases: ['e'],
                           desc: 'Edit prompt before submitting to claude'
      option :output_path, type: :string, default: nil, aliases: ['o'],
                           desc: 'Path to save test file'
      option :stdout, type: :boolean, default: false, aliases: ['s'],
                      desc: 'Output test file to stdout instead of writing to test file'
      option :force, type: :boolean, default: false, aliases: ['f'],
                     desc: 'Force overwrite of existing test file'
      option :open, type: :boolean, default: false, aliases: ['p'],
                    desc: 'Open test file in editor after generation'

      def initialize
        @config = Vercon::Config.new
        @stdout = Vercon::Stdout.new
        @files = Dry::Files.new

        super
      end

      def call(path: nil, **opts)
        return unless can_generate?(path, opts)

        output_path = opts[:output_path] || generate_test_file_path(path, opts)
        return if output_path.nil?

        current_test = files.exist?(output_path) ? files.read(output_path) : nil

        result = generate_test_file(path, opts, current_test)

        if opts[:stdout]
          pager = TTY::Pager.new
          pager.page(result)
          return
        end

        if !opts[:force] && files.exist?(output_path) && stdout.no?("File already exists at \"#{output_path}\". Overwrite?")
          return
        end

        files.write(output_path, result)

        run_rubocop(output_path) if include_gem?('rubocop') || include_gem?('standard')

        stdout.ok("Test file saved at \"#{output_path}\" 🥳")

        return unless opts[:open]

        TTY::Editor.new(raise_on_failure: true).open(output_path)
      end

      private

      attr_reader :config, :stdout, :files

      def can_generate?(path, _opts)
        unless config.exists?
          stdout.error('Config file does not exist. Run `vercon init` to create a config file.')
          return false
        end

        if path.nil? || path.empty?
          stdout.error('Path to ruby file is blank.')
          return false
        end

        unless files.exist?(path)
          stdout.error('Ruby file does not exist.')
          return false
        end

        expanded_path = files.expand_path(path)

        if Prism.parse_file_failure?(expanded_path)
          stdout.error('Looks like the ruby file has syntax errors. Fix them before generating tests.')
          return false
        end

        unless include_gem?('rspec')
          stdout.error('RSpec is not installed. Vercon requires RSpec to generate test files.')
          return false
        end

        true
      end

      def generate_test_file_path(path, _opts)
        system, user, stop_sequence = Vercon::Prompt.for_test_path(path: path)
        spinner = TTY::Spinner.new('[:spinner] Preparing spec file path...', format: :flip)
        spinner.auto_spin

        result = Vercon::Claude.new.submit(
          model: config.class::LOWEST_CLAUDE_MODEL,
          system: system, user: user,
          stop_sequences: [stop_sequence]
        )
        spinner.stop
        stdout.erase(lines: 1)

        if result.key?(:error)
          stdout.error("Claude returned error: #{result[:error]}")
          return
        end

        path = result[:text].match(/RSPEC FILE PATH: "(.+)"/)[1]

        if stdout.no?("Corresponding test file path should be \"#{path}\". Correct?")
          path = stdout.ask('Enter a relative path of corresponding test:')
        end

        path
      end

      def generate_test_file(path, opts, current_test)
        factories = Vercon::Factories.new.load if include_gem?('factory_bot')
        system, user, stop_sequence = Vercon::Prompt.for_test_generation(
          path: path, source: files.read(path),
          factories: factories, current_test: current_test
        )
        system, user = ask_for_edits(system, user) if opts[:edit_prompt]
        return if system.nil? || user.nil?

        spinner = TTY::Spinner.new('[:spinner] Generating spec file...', format: :flip)
        spinner.auto_spin

        result = Vercon::Claude.new.submit(system: system, user: user, stop_sequences: [stop_sequence])
        spinner.stop
        stdout.erase(lines: 1)

        if result.key?(:error)
          stdout.error("Claude returned error: #{result[:error]}")
          return
        end

        result[:text].match(/TEST SOURCE CODE:\n```ruby\n(.+)\n```/m)[1]
      end

      def run_rubocop(path)
        spinner = TTY::Spinner.new('[:spinner] Running RuboCop...', format: :flip)
        spinner.auto_spin

        system("bundle exec rubocop -A #{files.expand_path(path)} > /dev/null 2>&1")

        spinner.stop
        stdout.erase(lines: 1)
      end

      def ask_for_edits(system, user)
        path = '~/.vercon_prompt.txt'
        text = <<~EOF.strip
          Please, do not remove magick comments :)
          <System prompt>
          #{system}
          <User prompt>
          #{user}
        EOF

        files.write(path, text)

        TTY::Editor.new(raise_on_failure: true).open(path)
        TTY::Spinner.new('[:spinner] Waiting for changes...', format: :flip).run { sleep(rand(1..3)) }
        stdout.erase(lines: 1)

        if stdout.no?('Can we proceed?')
          stdout.error('Generation aborted!')
          return []
        end

        system, user = files.read(path).match(/<System prompt>\n(.+)\n<User prompt>\n(.+)/m).captures

        [system, user]
      ensure
        files.delete(path)
      end

      def include_gem?(name)
        files.read('Gemfile').include?(name)
      end
    end
  end
end
