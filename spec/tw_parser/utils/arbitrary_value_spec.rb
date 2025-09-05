# frozen_string_literal: true

require "tw_parser/utils/arbitrary_value"

RSpec.describe TwParser::Utils::ArbitraryValue do
  describe ".decode" do
    subject { described_class.decode(input) }

    {
      "var(--foo)" => "var(--foo)",
      "foo_bar" => "foo bar",
      "foo\\_bar" => "foo_bar",
      "var(--foo_foo,bar_bar)" => "var(--foo_foo,bar bar)"
    }.each do |input, expected|
      context "when input is \"#{input}\"" do
        let(:input) { input }
        it { is_expected.to eq(expected) }
      end
    end
  end
end
