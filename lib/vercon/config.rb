# frozen_string_literal: true

require 'yaml'
require 'dry/files'

module Vercon
  class Config
    CLAUDE_MODELS = %w[
      claude-3-haiku-20240307
      claude-3-sonnet-20240229
      claude-3-opus-20240229
    ].freeze
    DEFAULT_CLAUDE_MODEL = 'claude-3-sonnet-20240229'
    LOWEST_CLAUDE_MODEL = 'claude-3-haiku-20240307'
    PATH = '~/.vercon.yml'

    def initialize
      @files = Dry::Files.new
      @config = YAML.load_file(@files.expand_path(PATH))
    rescue Errno::ENOENT
      @config = {}
    end

    def exists?
      !@config.empty?
    end

    def token
      @config['claude_token']
    end

    def token=(value)
      @config['claude_token'] = value
      @files.write(@files.expand_path(PATH), YAML.safe_dump(@config))
    end

    def claude_model
      @config['claude_model']
    end

    def claude_model=(value)
      @config['claude_model'] = value
      @files.write(@files.expand_path(PATH), YAML.safe_dump(@config))
    end
  end
end
