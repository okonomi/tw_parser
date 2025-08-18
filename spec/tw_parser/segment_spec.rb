# frozen_string_literal: true

require "tw_parser/segment"

RSpec.describe TwParser do
  describe ".segment" do
    subject { described_class.segment(input, delimiter) }

    context "when input is correct" do
      {
        "foo" => %w[foo],
        "foo:bar:baz" => %w[foo bar baz],
        "a:(b:c):d" => %w[a (b:c) d],
        "a:[b:c]:d" => %w[a [b:c] d],
        "a:{b:c}:d" => %w[a {b:c} d],
        'a:"b:c":d' => ["a", '"b:c"', "d"],
        "a:'b:c':d" => ["a", "'b:c'", "d"]
      }.each do |input, expected|
        context "with #{input}" do
          let(:input) { input }
          let(:delimiter) { ":" }

          it { is_expected.to eq(expected) }
        end
      end
    end

    context "when input is incorrect" do
      {
        'a:"b:c:d' => ["a", '"b:c:d'],
        "a:'b:c:d" => ["a", "'b:c:d"]
      }.each do |input, expected|
        context "with #{input}" do
          let(:input) { input }
          let(:delimiter) { ":" }

          it { is_expected.to eq(expected) }
        end
      end
    end
  end
end
