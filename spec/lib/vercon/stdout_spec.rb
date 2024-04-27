# frozen_string_literal: true

require "vercon/stdout"

RSpec.describe Vercon::Stdout do
  let(:prompt) { instance_double(TTY::Prompt) }
  subject(:stdout) { described_class.new }

  before { allow(TTY::Prompt).to receive(:new).and_return(prompt) }

  describe "#write" do
    it "writes the message to stdout" do
      expect { stdout.write("Hello") }.to output("Hello\n").to_stdout
    end

    it "increments the lines count" do
      expect { stdout.write("Hello") }.to change { stdout.instance_variable_get(:@lines) }.by(1)
    end

    context "when the message contains multiple lines" do
      it "increments the lines count accordingly" do
        expect { stdout.write("Line 1\nLine 2\nLine 3") }.to change { stdout.instance_variable_get(:@lines) }.by(3)
      end
    end
  end

  describe "#erase" do
    let(:real_stdout) { double("real_stdout") }

    before do
      stdout.instance_variable_set(:@stdout, real_stdout)
      allow(real_stdout).to receive(:print)
    end

    context "when lines argument is provided" do
      it "erases the specified number of lines" do
        stdout.instance_variable_set(:@lines, 5)

        stdout.erase(lines: 3)

        expect(real_stdout).to have_received(:print).with("\e[A\e[K").exactly(3).times
        expect(stdout.instance_variable_get(:@lines)).to eq(2)
      end
    end

    context "when lines argument is not provided" do
      it "erases all the lines" do
        stdout.instance_variable_set(:@lines, 5)

        stdout.erase

        expect(real_stdout).to have_received(:print).with("\e[A\e[K").exactly(5).times
        expect(stdout.instance_variable_get(:@lines)).to eq(0)
      end
    end

    context "when there are no lines to erase" do
      it "does not erase any lines" do
        stdout.instance_variable_set(:@lines, 0)

        stdout.erase

        expect(real_stdout).not_to have_received(:print)
        expect(stdout.instance_variable_get(:@lines)).to eq(0)
      end
    end
  end

  describe "prompt methods delegation" do
    %i[ask yes? no? say ok warn error mask select].each do |method|
      describe "##{method}" do
        it "delegates the method to the prompt instance" do
          expect(prompt).to receive(method).with("Question")
          stdout.send(method, "Question")
        end

        it "increments the lines count" do
          allow(prompt).to receive(method)

          expect { stdout.send(method, "Question") }.to change { stdout.instance_variable_get(:@lines) }.by(1)
          expect(prompt).to have_received(method)
        end

        context "when the message contains multiple lines" do
          it "increments the lines count accordingly" do
            allow(prompt).to receive(method)

            expect { stdout.send(method, "Line 1\nLine 2\nLine 3") }.to change { stdout.instance_variable_get(:@lines) }.by(3)
            expect(prompt).to have_received(method)
          end
        end
      end
    end
  end

  describe "stdout methods delegation" do
    %i[puts print].each do |method|
      describe "##{method}" do
        it "delegates the method to the stdout instance" do
          expect(stdout.instance_variable_get(:@stdout)).to receive(method).with("Message")
          stdout.send(method, "Message")
        end

        it "increments the lines count" do
          expect { stdout.send(method, "Message") }.to change { stdout.instance_variable_get(:@lines) }.by(1)
        end

        context "when the message contains multiple lines" do
          it "increments the lines count accordingly" do
            expect { stdout.send(method, "Line 1\nLine 2\nLine 3") }.to change { stdout.instance_variable_get(:@lines) }.by(3)
          end
        end
      end
    end
  end
end
