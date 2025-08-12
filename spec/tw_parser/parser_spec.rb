# frozen_string_literal: true

RSpec.describe TwParser::Parser do
  describe "#parse" do
    subject { described_class.new.parse(input) }

    context "when basic input is provided" do
      let(:input) { "bg-red-100" }

      it { is_expected.to eq({}) }
    end
  end
end
