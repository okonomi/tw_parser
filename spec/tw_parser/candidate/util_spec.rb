# frozen_string_literal: true

require_relative "../../../lib/tw_parser/candidate/util"

RSpec.describe TwParser::Candidate::Util do
  describe ".extract_candidate_info" do
    subject { described_class.extract_candidate_info(candidate) }

    context "when candidate is a static variant" do
      let(:candidate) do
        TwParser::Candidate::StaticVariant.new(
          root: "hover"
        )
      end

      it do
        is_expected.to eq(
          {
            kind: :static,
            root: "hover"
          }
        )
      end
    end

    context "when candidate is an arbitrary variant" do
      let(:candidate) do
        TwParser::Candidate::ArbitraryVariant.new(
          selector: ".custom",
          relative: false
        )
      end

      it do
        is_expected.to eq(
          {
            kind: :arbitrary,
            selector: ".custom",
            relative: false
          }
        )
      end
    end

    context "when candidate is a functional variant" do
      let(:candidate) do
        TwParser::Candidate::FunctionalVariant.new(
          root: "data",
          value: TwParser::Candidate::NamedVariantValue.new(value: "foo"),
          modifier: TwParser::Candidate::NamedModifier.new(value: "50")
        )
      end

      it do
        is_expected.to eq(
          {
            kind: :functional,
            root: "data",
            value: {
              kind: :named,
              value: "foo"
            },
            modifier: {
              kind: :named,
              value: "50"
            }
          }
        )
      end
    end

    context "when candidate is a static candidate" do
      let(:candidate) do
        TwParser::Candidate::StaticCandidate.new(
          root: "flex",
          variants: [],
          important: false,
          raw: "flex"
        )
      end

      it do
        is_expected.to eq(
          {
            kind: :static,
            root: "flex",
            variants: [],
            important: false,
            raw: "flex"
          }
        )
      end
    end

    context "when candidate is an arbitrary candidate" do
      let(:candidate) do
        TwParser::Candidate::ArbitraryCandidate.new(
          property: "color",
          value: "red",
          modifier: TwParser::Candidate::NamedModifier.new(value: "50"),
          variants: [],
          important: true,
          raw: "[color:red]/50!"
        )
      end

      it do
        is_expected.to eq(
          {
            kind: :arbitrary,
            property: "color",
            value: "red",
            modifier: {
              kind: :named,
              value: "50"
            },
            variants: [],
            important: true,
            raw: "[color:red]/50!"
          }
        )
      end
    end

    context "when candidate is a functional candidate" do
      let(:candidate) do
        TwParser::Candidate::FunctionalCandidate.new(
          root: "bg",
          value: TwParser::Candidate::NamedUtilityValue.new(value: "red-500", fraction: nil),
          modifier: TwParser::Candidate::ArbitraryModifier.new(value: "var(--opacity)"),
          variants: [],
          important: false,
          raw: "bg-red-500/[var(--opacity)]"
        )
      end

      it do
        is_expected.to eq(
          {
            kind: :functional,
            root: "bg",
            value: {
              kind: :named,
              value: "red-500",
              fraction: nil
            },
            modifier: {
              kind: :arbitrary,
              value: "var(--opacity)"
            },
            variants: [],
            important: false,
            raw: "bg-red-500/[var(--opacity)]"
          }
        )
      end
    end

    context "when candidate has complex class name with multiple words" do
      let(:candidate) do
        TwParser::Candidate::ArbitraryVariant.new(
          selector: ".test",
          relative: true
        )
      end

      it "extracts the first word as kind" do
        is_expected.to eq(
          {
            kind: :arbitrary,
            selector: ".test",
            relative: true
          }
        )
      end
    end
  end
end
