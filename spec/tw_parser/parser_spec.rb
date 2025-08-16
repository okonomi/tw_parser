# frozen_string_literal: true

RSpec.describe TwParser::Parser do
  describe "#parse" do
    subject { described_class.new.parse(input) }

    context "should parse a simple utility" do
      let(:input) { "flex" }

      it {
        is_expected.to eq(TwParser::StaticCandidate.new(
                            important: false,
                            raw: "flex",
                            root: "flex",
                            variants: []
                          ))
      }
    end

    context "should parse a simple utility that should be important" do
      let(:input) { "flex!" }

      it {
        is_expected.to eq(TwParser::StaticCandidate.new(
                            important: true,
                            raw: "flex!",
                            root: "flex",
                            variants: []
                          ))
      }
    end

    context "should parse a simple utility that can be negative" do
      let(:input) { "-translate-x-4" }

      it {
        is_expected.to eq(TwParser::FunctionalCandidate.new(
                            important: false,
                            modifier: nil,
                            raw: "-translate-x-4",
                            root: "-translate-x",
                            value: TwParser::NamedUtilityValue.new(
                              fraction: nil,
                              value: "4"
                            ),
                            variants: []
                          ))
      }
    end
  end
end
