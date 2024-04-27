# frozen_string_literal: true

require_relative "../version"

module Vercon
  module Commands
    class Version < Dry::CLI::Command
      desc "Print version"

      def initialize
        @stdout = Vercon::Stdout.new

        super
      end

      def call(*)
        @stdout.puts ::Vercon::VERSION
      end
    end
  end
end
