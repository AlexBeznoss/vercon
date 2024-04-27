# frozen_string_literal: true

require "vercon/prompt"

RSpec.describe Vercon::Prompt do
  describe ".for_test_path" do
    let(:path) { "./some fake path.rb" }
    subject { described_class.for_test_path(path: path) }

    it "returns system, user and stop_sequences" do
      expect(subject.keys).to match_array([:system, :user, :stop_sequences])
    end

    describe "system" do
      it "includes end sequence" do
        expect(subject[:system]).to include(described_class::END_SEQUENCE)
      end
    end

    describe "user" do
      it "includes path" do
        expect(subject[:user]).to eq("PATH: \"#{path}\"")
      end
    end

    describe "stop_sequences" do
      it "includes end sequence" do
        expect(subject[:stop_sequences]).to eq([described_class::END_SEQUENCE])
      end
    end
  end

  describe ".for_test_generation" do
    let(:path) { "./some fake path.rb" }
    let(:source) { "source code" }
    let(:factories) { nil }
    let(:current_test) { nil }

    subject { described_class.for_test_generation(path: path, source: source, factories: factories, current_test: current_test) }

    it "returns system, user and tools" do
      expect(subject.keys).to match_array([:system, :user, :tools])
    end

    describe "user" do
      let(:result) do
        <<~PROMPT.strip
          PATH: #{path.inspect}
          CODE:
          ```ruby
          #{source}
          ```
        PROMPT
      end

      it "includes path and source" do
        expect(subject[:user]).to eq(result)
      end

      context "with factories" do
        let(:factories) { [{name: "user", trails: %w[admin]}] }
        let(:result) do
          <<~PROMPT.strip
            PATH: #{path.inspect}
            AVAILABLE FACTORIES:
            ```json
            [{"name":"user","trails":["admin"]}]
            ```
            CODE:
            ```ruby
            #{source}
            ```
          PROMPT
        end

        it "includes factories" do
          expect(subject[:user]).to eq(result)
        end
      end

      context "with current test" do
        let(:current_test) { "some fake current test" }
        let(:result) do
          <<~PROMPT.strip
            PATH: #{path.inspect}
            CODE:
            ```ruby
            #{source}
            ```
            CURRENT RSPEC FILE:
            ```ruby
            #{current_test}
            ```
          PROMPT
        end

        it "includes current test" do
          expect(subject[:user]).to eq(result)
        end
      end
    end
  end
end
