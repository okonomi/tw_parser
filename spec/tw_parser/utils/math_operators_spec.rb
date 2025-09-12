# frozen_string_literal: true

require "tw_parser/utils/math_operators"

RSpec.describe TwParser::Utils::MathOperators do
  describe ".add_whitespace" do
    subject { described_class.add_whitespace(input) }

    {
      "calc(1+1)" => "calc(1 + 1)",
      "calc(100%-4px)" => "calc(100% - 4px)",
      "var(--foo)" => "var(--foo)",
      "calc(1+-2)" => "calc(1 + -2)",
      "calc(+2--3)" => "calc(+2 - -3)",
      "calc( (1+2) -(-3) )" => "calc( (1 + 2) - (-3) )",
      "calc(10px,2px)" => "calc(10px, 2px)"
      # "var(--foo+bar)" => "var(--foo+bar)",
      # "url(https://example.com/some_page?foo=bar_baz+qux)" => "url(https://example.com/some_page?foo=bar_baz+qux)"
    }.each do |input, expected|
      context "when input is \"#{input}\"" do
        let(:input) { input }
        it { is_expected.to eq(expected) }
      end
    end
  end
end
