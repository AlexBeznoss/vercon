# frozen_string_literal: true

require 'vercon/stdout'

RSpec.describe Vercon::Stdout do
  let(:prompt) { instance_double(TTY::Prompt) }
  subject(:stdout) { described_class.new }

  before { allow(TTY::Prompt).to receive(:new).and_return(prompt) }

  describe '#write' do
    it 'writes the message to stdout' do
      expect { stdout.write('Hello') }.to output("Hello\n").to_stdout
    end

    it 'increments the lines count' do
      expect { stdout.write('Hello') }.to change { stdout.instance_variable_get(:@lines) }.by(1)
    end
  end

  describe '#erase' do
    let(:real_stdout) { double('real_stdout') }

    before do
      stdout.instance_variable_set(:@stdout, real_stdout)
      allow(real_stdout).to receive(:print)
    end

    context 'when lines argument is provided' do
      it 'erases the specified number of lines' do
        stdout.instance_variable_set(:@lines, 5)

        stdout.erase(lines: 3)

        expect(real_stdout).to have_received(:print).with("\e[A\e[K").exactly(3).times
        expect(stdout.instance_variable_get(:@lines)).to eq(2)
      end
    end

    context 'when lines argument is not provided' do
      it 'erases all the lines' do
        stdout.instance_variable_set(:@lines, 5)

        stdout.erase

        expect(real_stdout).to have_received(:print).with("\e[A\e[K").exactly(5).times
        expect(stdout.instance_variable_get(:@lines)).to eq(0)
      end
    end
  end

  describe '#respond_to_missing?' do
    context 'when the method is included in PROMPT_METHODS' do
      it 'returns true' do
        expect(stdout.respond_to?(:ask)).to be true
      end
    end

    context 'when the method is included in STDOUT_METHODS' do
      it 'returns true' do
        expect(stdout.respond_to?(:puts)).to be true
      end
    end

    context 'when the method is not included in PROMPT_METHODS or STDOUT_METHODS' do
      it 'returns false' do
        expect(stdout.respond_to?(:unknown_method)).to be false
      end
    end
  end

  describe '#method_missing' do
    context 'when the method is included in PROMPT_METHODS' do
      it 'delegates the method to the prompt instance' do
        expect(stdout.instance_variable_get(:@prompt)).to receive(:ask).with('Question')
        stdout.ask('Question')
      end

      it 'increments the lines count' do
        allow(prompt).to receive(:ask)

        expect { stdout.ask('Question') }.to change { stdout.instance_variable_get(:@lines) }.by(1)
        expect(prompt).to have_received(:ask)
      end
    end

    context 'when the method is included in STDOUT_METHODS' do
      it 'delegates the method to the stdout instance' do
        expect(stdout.instance_variable_get(:@stdout)).to receive(:puts).with('Message')
        stdout.puts('Message')
      end

      it 'increments the lines count' do
        expect { stdout.puts('Message') }.to change { stdout.instance_variable_get(:@lines) }.by(1)
      end
    end

    context 'when the method is not included in PROMPT_METHODS or STDOUT_METHODS' do
      it 'raises NoMethodError' do
        expect { stdout.unknown_method }.to raise_error(NoMethodError)
      end
    end
  end
end
