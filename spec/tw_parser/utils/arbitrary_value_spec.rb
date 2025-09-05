# frozen_string_literal: true

require "tw_parser/utils/arbitrary_value"

RSpec.describe TwParser::Utils::ArbitraryValue do
  describe ".decode" do
    subject { described_class.decode(input) }

    {
      "var(--foo)" => "var(--foo)",
      "foo_bar" => "foo bar",
      "foo\\_bar" => "foo_bar",
      "var(--foo_foo,bar_bar)" => "var(--foo_foo,bar bar)",
      "var(--a,b_var(--c_d))" => "var(--a,b var(--c_d))"
    }.each do |input, expected|
      context "when input is \"#{input}\"" do
        let(:input) { input }
        it { is_expected.to eq(expected) }
      end
    end
  end

  describe ".valid?" do
    subject { described_class.valid?(input) }

    context "when input is valid" do
      [
        "",
        "#ffffff"
      ].each do |input|
        context "with \"#{input}\"" do
          let(:input) { input }

          it { is_expected.to be true }
        end
      end
    end

    context "when input is invalid" do
      [
        "foo;bar"
      ].each do |input|
        context "with \"#{input}\"" do
          let(:input) { input }

          it { is_expected.to be false }
        end
      end
    end
  end
end
