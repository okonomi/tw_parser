# frozen_string_literal: true

require "tw_parser/utils/math_operators"

RSpec.describe TwParser::Utils::MathOperators do
  describe ".add_whitespace" do
    subject { described_class.add_whitespace(input) }

    {
      "1+1" => "1 + 1",
      "100%-4px" => "100% - 4px",
      "var(--foo)" => "var(--foo)"
      # "calc(100% - 4px)" => "calc(100% - 4px)",
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
