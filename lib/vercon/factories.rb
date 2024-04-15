# frozen_string_literal: true

require 'dry/files'
require 'prism'

module Vercon
  class Factories
    PATH = './spec/factories'

    def initialize
      @files = Dry::Files.new
    end

    def load
      return unless @files.directory?(PATH)

      Dir[@files.expand_path(@files.join(PATH, '**', '*.rb'))].map do |file_path|
        load_factory(file_path)
      end.flatten.compact
    end

    private

    def load_factory(file_path)
      factories = []

      tree = Prism.parse_file(file_path)
      return if tree.failure?

      factory_node = find_factory_node(tree.value)
      return unless factory_node

      factory_node.block.body.body.each do |node|
        factories << parse_factory(node) if node.type == :call_node && node.name == :factory
      end

      factories
    end

    def find_factory_node(node)
      case node.type
      when :call_node
        node if node.name == :define && node.receiver.name == :FactoryBot
      when :program_node, :statements_node
        node.child_nodes.map { |inner_node| find_factory_node(inner_node) }.find(&:itself)
      end
    end

    def parse_factory(node)
      factory = {
        name: node.arguments.child_nodes.first.unescaped
      }

      traits = node.block.body.child_nodes.map do |cnode|
        next unless cnode.type == :call_node && cnode.name == :trait

        cnode.arguments.child_nodes.first.unescaped
      end.compact

      factory[:traits] = traits unless traits.empty?

      factory
    end
  end
end
