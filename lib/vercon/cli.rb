# frozen_string_literal: true

require 'dry/cli'

require_relative 'commands/init'
require_relative 'commands/generate'

module Vercon
  class CLI
    extend Dry::CLI::Registry

    register 'init', Commands::Init, aliases: ['i']
    register 'generate', Commands::Generate, aliases: ['g']
  end
end
