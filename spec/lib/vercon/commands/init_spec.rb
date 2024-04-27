# frozen_string_literal: true

require "vercon/commands/init"
require "vercon/stdout"
require "vercon/config"

RSpec.describe Vercon::Commands::Init do
  let(:stdout) { instance_double(Vercon::Stdout) }
  let(:config) { instance_double(Vercon::Config) }

  before do
    allow(Vercon::Stdout).to receive(:new).and_return(stdout)
    allow(Vercon::Config).to receive(:new).and_return(config)
  end

  describe "#call" do
    context "when token and claude_model are provided as options" do
      let(:opts) { {claude_token: "test_token", claude_model: "test_model"} }

      before do
        allow(config).to receive(:exists?).and_return(true)
        allow(config).to receive(:claude_token=)
        allow(config).to receive(:claude_token).and_return(nil)
        allow(config).to receive(:claude_model=)
        allow(config).to receive(:claude_model).and_return(nil)
        allow(config).to receive(:open_by_default=)
        allow(stdout).to receive(:ok)
        allow(stdout).to receive(:select)
      end

      it "sets the token, claude_model, and open_by_default in the config" do
        expect(config).to receive(:claude_token=).with("test_token")
        expect(config).to receive(:claude_model=).with("test_model")
        expect(config).to receive(:open_by_default=).with(nil)
        subject.call(**opts)
      end

      it "outputs a success message indicating the config file is updated" do
        expect(stdout).to receive(:ok).with("Config file updated!")
        subject.call(**opts)
      end
    end

    context "when token and claude_model are not provided as options" do
      let(:opts) { {open: true} }

      before do
        allow(config).to receive(:exists?).and_return(false)
        allow(config).to receive(:claude_token).and_return(nil)
        allow(config).to receive(:claude_model).and_return(nil)
        allow(stdout).to receive(:ask).and_return("test_token")
        allow(stdout).to receive(:select).and_return("test_model")
        allow(stdout).to receive(:ok)
        allow(config).to receive(:claude_token=)
        allow(config).to receive(:claude_model=)
        allow(config).to receive(:open_by_default=)
      end

      it "prompts for the token and sets it in the config" do
        expect(stdout).to receive(:ask).with("Provide your Claude API token:")
        expect(config).to receive(:claude_token=).with("test_token")
        subject.call(**opts)
      end

      it "prompts for the claude_model and sets it in the config" do
        expect(stdout).to receive(:select).with(
          "Select Claude model that will be used by default:",
          Vercon::Config::CLAUDE_MODELS,
          default: Vercon::Config::DEFAULT_CLAUDE_MODEL,
          cycle: true
        )
        expect(config).to receive(:claude_model=).with("test_model")
        subject.call(**opts)
      end

      it "sets open_by_default based on the provided option" do
        expect(config).to receive(:open_by_default=).with(true)
        subject.call(**opts)
      end

      it "outputs a success message indicating the config file is created" do
        expect(stdout).to receive(:ok).with("Config file created!")
        subject.call(**opts)
      end
    end

    context "when token is already set but claude_model is not" do
      let(:opts) { {} }

      before do
        allow(config).to receive(:exists?).and_return(true)
        allow(config).to receive(:claude_token).and_return("existing_token")
        allow(config).to receive(:claude_model).and_return(nil)
        allow(stdout).to receive(:no?).and_return(true, false)
        allow(stdout).to receive(:select).and_return("test_model")
        allow(stdout).to receive(:ok)
        allow(config).to receive(:claude_model=)
        allow(config).to receive(:open_by_default=)
      end

      it "does not update the token but prompts for and sets the claude_model" do
        expect(config).not_to receive(:claude_token=)
        expect(stdout).to receive(:select).with(
          "Select Claude model that will be used by default:",
          Vercon::Config::CLAUDE_MODELS,
          default: Vercon::Config::DEFAULT_CLAUDE_MODEL,
          cycle: true
        )
        expect(config).to receive(:claude_model=).with("test_model")
        subject.call(**opts)
      end

      it "prompts for open_by_default and sets it in the config" do
        expect(stdout).to receive(:select).with(
          "Open generated test file by default?",
          {Yes: true, No: false},
          default: "No",
          cycle: true
        )
        expect(config).to receive(:open_by_default=)
        subject.call(**opts)
      end

      it "outputs a success message indicating the config file is updated" do
        expect(stdout).to receive(:ok).with("Config file updated!")
        subject.call(**opts)
      end
    end

    context "when claude_model is already set but token is not" do
      let(:opts) { {} }

      before do
        allow(config).to receive(:exists?).and_return(true)
        allow(config).to receive(:claude_token).and_return(nil)
        allow(config).to receive(:claude_model).and_return("existing_model")
        allow(stdout).to receive(:no?).and_return(true)
        allow(stdout).to receive(:ask).and_return("test_token")
        allow(stdout).to receive(:ok)
        allow(stdout).to receive(:select)
        allow(config).to receive(:claude_token=)
        allow(config).to receive(:open_by_default=)
      end

      it "prompts for and sets the token but does not update the claude_model" do
        expect(stdout).to receive(:ask).with("Provide your Claude API token:")
        expect(config).to receive(:claude_token=).with("test_token")
        expect(config).not_to receive(:claude_model=)
        subject.call(**opts)
      end

      it "prompts for open_by_default and sets it in the config" do
        expect(stdout).to receive(:select).with(
          "Open generated test file by default?",
          {Yes: true, No: false},
          default: "No",
          cycle: true
        )
        expect(config).to receive(:open_by_default=)
        subject.call(**opts)
      end

      it "outputs a success message indicating the config file is updated" do
        expect(stdout).to receive(:ok).with("Config file updated!")
        subject.call(**opts)
      end
    end

    context "when token and claude_model are already set in the config" do
      let(:opts) { {} }

      before do
        allow(config).to receive(:exists?).and_return(true)
        allow(config).to receive(:claude_token).and_return("existing_token")
        allow(config).to receive(:claude_model).and_return("existing_model")
        allow(stdout).to receive(:no?).and_return(true, true)
        allow(stdout).to receive(:ok)
        allow(stdout).to receive(:select)
        allow(config).to receive(:open_by_default=)
      end

      it "does not update the token and claude_model in the config" do
        expect(config).not_to receive(:claude_token=)
        expect(config).not_to receive(:claude_model=)
        subject.call(**opts)
      end

      it "prompts for open_by_default and sets it in the config" do
        expect(stdout).to receive(:select).with(
          "Open generated test file by default?",
          {Yes: true, No: false},
          default: "No",
          cycle: true
        )
        expect(config).to receive(:open_by_default=)
        subject.call(**opts)
      end

      it "outputs a success message indicating the config file is updated" do
        expect(stdout).to receive(:ok).with("Config file updated!")
        subject.call(**opts)
      end
    end

    context "when an exception is raised" do
      let(:opts) { {} }

      before do
        allow(config).to receive(:exists?).and_raise(StandardError)
      end

      it "raises the exception" do
        expect { subject.call(**opts) }.to raise_error(StandardError)
      end
    end
  end
end
