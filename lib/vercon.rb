# frozen_string_literal: true

require_relative 'vercon/version'
require_relative 'vercon/config'
require_relative 'vercon/stdout'
require_relative 'vercon/cli'
require_relative 'vercon/claude'
require_relative 'vercon/prompt'
require_relative 'vercon/factories'

module Vercon
  class Error < StandardError; end
end
