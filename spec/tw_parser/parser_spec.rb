# frozen_string_literal: true

RSpec.describe TwParser::Parser do
  describe "#parse" do
    subject { described_class.new.parse(input) }

    {
      "flex" => TwParser::StaticCandidate.new(
        important: false,
        raw: "flex",
        root: "flex",
        variants: []
      ),
      "flex!" => TwParser::StaticCandidate.new(
        important: true,
        raw: "flex!",
        root: "flex",
        variants: []
      ),
      "hover:flex" => TwParser::StaticCandidate.new(
        important: false,
        raw: "hover:flex",
        root: "flex",
        variants: [
          TwParser::StaticVariant.new(
            root: "hover"
          )
        ]
      ),
      "focus:hover:flex" => TwParser::StaticCandidate.new(
        important: false,
        raw: "focus:hover:flex",
        root: "flex",
        variants: [
          TwParser::StaticVariant.new(
            root: "hover"
          ),
          TwParser::StaticVariant.new(
            root: "focus"
          )
        ]
      ),
      "-translate-x-4" => TwParser::FunctionalCandidate.new(
        important: false,
        modifier: nil,
        raw: "-translate-x-4",
        root: "-translate-x",
        value: TwParser::NamedUtilityValue.new(
          fraction: nil,
          value: "4"
        ),
        variants: []
      ),
      "bg-red-500/50" => TwParser::FunctionalCandidate.new(
        important: false,
        modifier: TwParser::NamedModifier.new(
          value: "50"
        ),
        raw: "bg-red-500/50",
        root: "bg",
        value: TwParser::NamedUtilityValue.new(
          fraction: "red-500/50",
          value: "red-500"
        ),
        variants: []
      )
    }.each do |input, expected|
      context input do
        let(:input) { input }
        it { is_expected.to eq(expected) }
      end
    end
  end
end
