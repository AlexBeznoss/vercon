# frozen_string_literal: true

require "vercon/factories"

RSpec.describe Vercon::Factories do
  describe "#load" do
    let(:files) { Dry::Files.new(memory: true) }
    before { allow(Dry::Files).to receive(:new).and_return(files) }

    subject { described_class.new.load }

    context "when no dir" do
      before { allow(files).to receive(:directory?).and_return(false) }

      it { is_expected.to be_nil }
    end

    context "when dir is empty" do
      before do
        allow(files).to receive(:directory?).and_return(true)
        allow(Dir).to receive(:[]).and_return([])
      end

      it { is_expected.to eq([]) }
    end

    context "when dir has files" do
      let(:result) do
        [
          {name: "user", traits: ["admin"]},
          {name: "publisher"},
          {name: "article", traits: %w[hidden published]}
        ]
      end

      before do
        allow(files).to receive(:directory?).and_return(true)
        examples = Dir["#{__dir__}/../../support/factory_examples/*.rb"]
        allow(Dir).to receive(:[]).and_return(examples)
        examples.each do |example|
          allow(Prism).to receive(:parse_file)
            .with(example)
            .and_return(Prism.parse(File.read(example)))
        end
      end

      it { is_expected.to match_array(result) }
    end
  end
end
