# frozen_string_literal: true

require "prism"
require "dry/files"
require "tty-spinner"
require "rouge"
require "tty-editor"

module Vercon
  module Commands
    class Generate < Dry::CLI::Command
      AUTOFIXERS = {
        standard: "bundle exec standardrb --fix %{file} > /dev/null 2>&1",
        rubocop: "bundle exec rubocop -a %{file} > /dev/null 2>&1"
      }

      desc "Generate test file"

      argument :path, desc: "Path to the ruby file"

      option :edit_prompt, type: :boolean, default: false, aliases: ["e"],
        desc: "Edit prompt before submitting to claude"
      option :output_path, type: :string, default: nil, aliases: ["o"],
        desc: "Path to save test file"
      option :stdout, type: :boolean, default: false, aliases: ["s"],
        desc: "Output test file to stdout instead of writing to test file"
      option :force, type: :boolean, default: false, aliases: ["f"],
        desc: "Force overwrite of existing test file"
      option :open, type: :boolean, default: nil, aliases: ["p"],
        desc: "Open test file in editor after generation"

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
        return if result.nil?

        result = run_autofixes(result)

        if opts[:stdout]
          formatter = Rouge::Formatters::Terminal256.new(Rouge::Themes::Base16::Monokai.new)
          lexer = Rouge::Lexers::Ruby.new

          stdout.puts(formatter.format(lexer.lex(result)))
          return
        end

        if !opts[:force] && files.exist?(output_path) && stdout.no?("File already exists at \"#{output_path}\". Overwrite?")
          return
        end

        files.write(output_path, result)

        stdout.ok("Test file saved at \"#{output_path}\" 🥳")

        if opts[:open] == true || (opts[:open].nil? && config.open_by_default?)
          TTY::Editor.new(raise_on_failure: true).open(output_path)
        end
      end

      private

      attr_reader :config, :stdout, :files

      def can_generate?(path, _opts)
        unless config.exists?
          stdout.error("Config file does not exist. Run `vercon init` to create a config file.")
          return false
        end

        if path.nil? || path.empty?
          stdout.error("Path to ruby file is blank.")
          return false
        end

        unless files.exist?(path)
          stdout.error("Ruby file does not exist.")
          return false
        end

        expanded_path = files.expand_path(path)

        if Prism.parse_file_failure?(expanded_path)
          stdout.error("Looks like the ruby file has syntax errors. Fix them before generating tests.")
          return false
        end

        unless include_gem?("rspec")
          stdout.error("RSpec is not installed. Vercon requires RSpec to generate test files.")
          return false
        end

        true
      end

      def generate_test_file_path(path, _opts)
        prompt = Vercon::Prompt.for_test_path(path: path)
        spinner = TTY::Spinner.new("[:spinner] Preparing spec file path...", format: :flip)
        spinner.auto_spin

        result = Vercon::Claude.new.submit(**prompt.merge(model: config.class::LOWEST_CLAUDE_MODEL))
        spinner.stop
        stdout.erase(lines: 1)

        if result.key?(:error)
          stdout.error("Claude returned error: #{result[:error]}")
          return
        end

        path, = result[:text].match(/RSPEC FILE PATH: "(.+)"/).captures

        if stdout.no?("Corresponding test file path should be \"#{path}\". Correct?")
          path = stdout.ask("Enter a relative path of corresponding test:")
        end

        path
      end

      def generate_test_file(path, opts, current_test)
        factories = Vercon::Factories.new.load if include_gem?("factory_bot")
        prompt = Vercon::Prompt.for_test_generation(
          path: path, source: files.read(path),
          factories: factories, current_test: current_test
        )
        prompt = ask_for_edits(**prompt) if opts[:edit_prompt]
        return if prompt[:system].nil? || prompt[:user].nil? || prompt[:tools].nil?

        spinner = TTY::Spinner.new("[:spinner] Generating spec file...", format: :flip)
        spinner.auto_spin

        result = Vercon::Claude.new.submit(**prompt)
        spinner.stop
        stdout.erase(lines: 1)

        if result.key?(:error)
          stdout.error("Claude returned error: #{result[:error]}")
          return
        end

        tool = result[:tools].find { |tool| tool[:name] == "write_test_file" }

        if tool.nil?
          stdout.error('Claude did not return the "write_test_file" tool. Aborting generation.')
          return nil
        end

        source = tool.dig(:input, "source_code")
        source = source.match(/```ruby\n(.+)\n```/m).captures.first if source.include?("```ruby")

        source
      end

      def run_autofixes(source)
        file = Tempfile.new("source_spec.rb")
        file.write(source)
        file.open

        AUTOFIXERS.each do |name, command|
          next unless include_gem?(name.to_s)

          spinner = TTY::Spinner.new("[:spinner] Running #{name}...", format: :flip)
          spinner.auto_spin

          system(format(command, file: file.path))

          spinner.stop
          stdout.erase(lines: 1)
        end

        file.read
      ensure
        file.unlink
      end

      def ask_for_edits(system:, user:, tools: nil)
        path = "~/.vercon_prompt.txt"
        text = []
        text << <<~EOF.strip
          Please, do not remove magick comments like <System prompt> and others :)
          #{tools.nil? ? "" : "When chaning tools, make sure to keep the general schema section intact, change descriptions only."}

          <System prompt>
          #{system}

          <User prompt>
          #{user}
        EOF
        text << <<~EOF.strip if tools
          <Tools>
          #{JSON.pretty_generate(tools)}
        EOF

        files.write(path, text.join("\n\n"))

        TTY::Editor.new(raise_on_failure: true).open(path)
        TTY::Spinner.new("[:spinner] Waiting for changes...", format: :flip).run { sleep(rand(1..3)) }
        stdout.erase(lines: 1)

        if stdout.no?("Can we proceed?")
          stdout.error("Generation aborted!")
          return {}
        end

        result = files.read(path)
        system, user = result.match(/<System prompt>(.+)\n<User prompt>(.+)/m).captures
        if tools
          user = user.match(/^(.+)\n\n<Tools>/m).captures.first
          tools = result.match(/<Tools>(.+)/m)&.captures&.first
          tools = JSON.parse(tools)
        end

        {system: system, user: user, tools: tools}.reject { |_, v| v.nil? }
      ensure
        files.delete(path)
      end

      def include_gem?(name)
        files.read("Gemfile").include?(name)
      end
    end
  end
end
