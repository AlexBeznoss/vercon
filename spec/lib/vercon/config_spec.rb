# frozen_string_literal: true

require "vercon/config"

RSpec.describe Vercon::Config do
  let(:config) { described_class.new }
  let(:config_path) { Dry::Files.new.expand_path(described_class::PATH) }
  let(:files) { Dry::Files.new(memory: true) }

  before { allow(Dry::Files).to receive(:new).and_return(files) }

  describe "#initialize" do
    context "when config file exists" do
      before do
        allow(YAML).to receive(:load_file).and_return(
          "claude_token" => "test_token",
          "claude_model" => "test_model"
        )
      end

      it "loads the config from the file" do
        expect(config.instance_variable_get(:@config)).to eq(
          "claude_token" => "test_token",
          "claude_model" => "test_model"
        )
      end
    end

    context "when config file does not exist" do
      before do
        allow(YAML).to receive(:load_file).and_raise(Errno::ENOENT)
      end

      it "initializes an empty config" do
        expect(config.instance_variable_get(:@config)).to eq({})
      end
    end
  end

  describe "#exists?" do
    context "when config is empty" do
      before do
        config.instance_variable_set(:@config, {})
      end

      it "returns false" do
        expect(config.exists?).to be false
      end
    end

    context "when config is not empty" do
      before do
        config.instance_variable_set(:@config, {"claude_token" => "test_token"})
      end

      it "returns true" do
        expect(config.exists?).to be true
      end
    end
  end

  describe "#claude_token" do
    before do
      config.instance_variable_set(:@config, {"claude_token" => "test_token"})
    end

    it "returns the claude_token from the config" do
      expect(config.claude_token).to eq("test_token")
    end
  end

  describe "#claude_model" do
    before do
      config.instance_variable_set(:@config, {"claude_model" => "test_model"})
    end

    it "returns the claude_model from the config" do
      expect(config.claude_model).to eq("test_model")
    end
  end

  describe "#open_by_default?" do
    context "when open_by_default is not set in the config" do
      before do
        config.instance_variable_set(:@config, {})
      end

      it "returns false" do
        expect(config.open_by_default?).to be false
      end
    end

    context "when open_by_default is set to true in the config" do
      before do
        config.instance_variable_set(:@config, {"open_by_default" => true})
      end

      it "returns true" do
        expect(config.open_by_default?).to be true
      end
    end

    context "when open_by_default is set to false in the config" do
      before do
        config.instance_variable_set(:@config, {"open_by_default" => false})
      end

      it "returns false" do
        expect(config.open_by_default?).to be false
      end
    end
  end

  describe "#claude_token=" do
    it "sets the claude_token in the config" do
      config.claude_token = "new_token"
      expect(config.instance_variable_get(:@config)["claude_token"]).to eq("new_token")
    end

    it "writes the updated config to the file" do
      expect(files).to receive(:write).with(config_path, YAML.safe_dump({"claude_token" => "new_token"}))
      config.claude_token = "new_token"
    end
  end

  describe "#claude_model=" do
    it "sets the claude_model in the config" do
      config.claude_model = "new_model"
      expect(config.instance_variable_get(:@config)["claude_model"]).to eq("new_model")
    end

    it "writes the updated config to the file" do
      expect(files).to receive(:write).with(config_path, YAML.safe_dump({"claude_model" => "new_model"}))
      config.claude_model = "new_model"
    end
  end

  describe "#open_by_default=" do
    it "sets the open_by_default in the config" do
      config.open_by_default = true
      expect(config.instance_variable_get(:@config)["open_by_default"]).to be true
    end

    it "writes the updated config to the file" do
      expect(files).to receive(:write).with(config_path, YAML.safe_dump({"open_by_default" => true}))
      config.open_by_default = true
    end
  end
end
