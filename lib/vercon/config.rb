# frozen_string_literal: true

require "yaml"
require "dry/files"

module Vercon
  class Config
    CLAUDE_MODELS = %w[
      claude-3-haiku-20240307
      claude-3-sonnet-20240229
      claude-3-opus-20240229
    ].freeze
    DEFAULT_CLAUDE_MODEL = "claude-3-sonnet-20240229"
    LOWEST_CLAUDE_MODEL = "claude-3-haiku-20240307"
    PATH = "~/.vercon.yml"

    def initialize
      @files = Dry::Files.new
      @config = YAML.load_file(@files.expand_path(PATH))
    rescue Errno::ENOENT
      @config = {}
    end

    def exists?
      !@config.empty?
    end

    def claude_token
      @config["claude_token"]
    end

    def claude_model
      @config["claude_model"]
    end

    def open_by_default?
      @config["open_by_default"].nil? ? false : @config["open_by_default"]
    end

    %i[claude_token claude_model open_by_default].each do |method|
      define_method(:"#{method}=") do |value|
        @config[method.to_s] = value
        write_config
      end
    end

    private

    def write_config
      @files.write(@files.expand_path(PATH), YAML.safe_dump(@config))
    end
  end
end
