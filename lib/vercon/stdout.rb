# frozen_string_literal: true

require "tty-prompt"

module Vercon
  class Stdout
    def initialize
      @stdout = $stdout
      @prompt = TTY::Prompt.new
      @lines = 0
    end

    def write(message)
      @stdout.puts(message)
      @lines += message.count("\n") + 1
    end

    def erase(lines: nil)
      (lines || @lines).times do
        @stdout.print("\e[A\e[K")
        @lines -= 1
      end
    end

    %i[ask yes? no? say ok warn error mask select].each do |method|
      define_method(method) do |*args, **params, &block|
        @lines += args.first.count("\n") + 1
        @prompt.send(method, *args, **params, &block)
      end
    end

    %i[puts print].each do |method|
      define_method(method) do |*args, **params, &block|
        @lines += args.first.count("\n") + 1
        @stdout.send(method, *args, **params, &block)
      end
    end
  end
end
