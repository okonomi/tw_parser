# frozen_string_literal: true

RSpec.describe TwParser::Candidate::Parser do
  describe "#parse" do
    subject do
      utilities = TwParser::Utilities.new.tap do |u|
        u.static("flex") { [] }
        u.functional("translate-x") { [] }
        u.functional("-translate-x") { [] }
        u.functional("bg") { [] }
      end
      variants = TwParser::Variants.new.tap do |v|
        v.functional("supports") {}
        v.functional("data") {}
        v.static("hover") {}
        v.static("focus") {}
      end
      described_class.new.parse(input, utilities:, variants:)
    end

    {
      "flex" => TwParser::Candidate::StaticCandidate.new(
        important: false,
        raw: "flex",
        root: "flex",
        variants: []
      ),
      "flex!" => TwParser::Candidate::StaticCandidate.new(
        important: true,
        raw: "flex!",
        root: "flex",
        variants: []
      ),
      "hover:flex" => TwParser::Candidate::StaticCandidate.new(
        important: false,
        raw: "hover:flex",
        root: "flex",
        variants: [
          TwParser::Candidate::StaticVariant.new(
            root: "hover"
          )
        ]
      ),
      "focus:hover:flex" => TwParser::Candidate::StaticCandidate.new(
        important: false,
        raw: "focus:hover:flex",
        root: "flex",
        variants: [
          TwParser::Candidate::StaticVariant.new(
            root: "hover"
          ),
          TwParser::Candidate::StaticVariant.new(
            root: "focus"
          )
        ]
      ),
      "-translate-x-4" => TwParser::Candidate::FunctionalCandidate.new(
        important: false,
        modifier: nil,
        raw: "-translate-x-4",
        root: "-translate-x",
        value: TwParser::Candidate::NamedUtilityValue.new(
          fraction: nil,
          value: "4"
        ),
        variants: []
      ),
      "bg-red-500/50" => TwParser::Candidate::FunctionalCandidate.new(
        important: false,
        modifier: TwParser::Candidate::NamedModifier.new(
          value: "50"
        ),
        raw: "bg-red-500/50",
        root: "bg",
        value: TwParser::Candidate::NamedUtilityValue.new(
          fraction: "red-500/50",
          value: "red-500"
        ),
        variants: []
      ),
      "bg-red-500/50!" => TwParser::Candidate::FunctionalCandidate.new(
        important: true,
        modifier: TwParser::Candidate::NamedModifier.new(
          value: "50"
        ),
        raw: "bg-red-500/50!",
        root: "bg",
        value: TwParser::Candidate::NamedUtilityValue.new(
          fraction: "red-500/50",
          value: "red-500"
        ),
        variants: []
      ),
      "hover:bg-red-500/50" => TwParser::Candidate::FunctionalCandidate.new(
        important: false,
        modifier: TwParser::Candidate::NamedModifier.new(
          value: "50"
        ),
        raw: "hover:bg-red-500/50",
        root: "bg",
        value: TwParser::Candidate::NamedUtilityValue.new(
          fraction: "red-500/50",
          value: "red-500"
        ),
        variants: [
          TwParser::Candidate::StaticVariant.new(
            root: "hover"
          )
        ]
      ),
      "bg-red-500/[50%]" => TwParser::Candidate::FunctionalCandidate.new(
        important: false,
        modifier: TwParser::Candidate::ArbitraryModifier.new(
          value: "50%"
        ),
        raw: "bg-red-500/[50%]",
        root: "bg",
        value: TwParser::Candidate::NamedUtilityValue.new(
          fraction: nil,
          value: "red-500"
        ),
        variants: []
      ),
      "[color:red]" => TwParser::Candidate::ArbitraryCandidate.new(
        important: false,
        modifier: nil,
        property: "color",
        raw: "[color:red]",
        value: "red",
        variants: []
      ),
      "[color:red]/50" => TwParser::Candidate::ArbitraryCandidate.new(
        important: false,
        modifier: TwParser::Candidate::NamedModifier.new(
          value: "50"
        ),
        property: "color",
        raw: "[color:red]/50",
        value: "red",
        variants: []
      ),
      "[color:red]!" => TwParser::Candidate::ArbitraryCandidate.new(
        important: true,
        modifier: nil,
        property: "color",
        raw: "[color:red]!",
        value: "red",
        variants: []
      ),
      "hover:[color:red]" => TwParser::Candidate::ArbitraryCandidate.new(
        important: false,
        modifier: nil,
        property: "color",
        raw: "hover:[color:red]",
        value: "red",
        variants: [
          TwParser::Candidate::StaticVariant.new(
            root: "hover"
          )
        ]
      ),
      "focus:hover:[color:red]" => TwParser::Candidate::ArbitraryCandidate.new(
        important: false,
        modifier: nil,
        property: "color",
        raw: "focus:hover:[color:red]",
        value: "red",
        variants: [
          TwParser::Candidate::StaticVariant.new(
            root: "hover"
          ),
          TwParser::Candidate::StaticVariant.new(
            root: "focus"
          )
        ]
      ),
      "[&_p]:flex" => TwParser::Candidate::StaticCandidate.new(
        important: false,
        raw: "[&_p]:flex",
        root: "flex",
        variants: [
          TwParser::Candidate::ArbitraryVariant.new(
            relative: false,
            selector: "& p"
          )
        ]
      ),
      "supports-(--test):flex" => TwParser::Candidate::StaticCandidate.new(
        important: false,
        raw: "supports-(--test):flex",
        root: "flex",
        variants: [
          TwParser::Candidate::FunctionalVariant.new(
            modifier: nil,
            root: "supports",
            value: TwParser::Candidate::ArbitraryVariantValue.new(
              value: "var(--test)"
            )
          )
        ]
      ),
      "unknown-utility" => nil,
      "unknown-variant:flex" => nil,
      "data-[disabled]:flex" => TwParser::Candidate::StaticCandidate.new(
        important: false,
        raw: "data-[disabled]:flex",
        root: "flex",
        variants: [
          TwParser::Candidate::FunctionalVariant.new(
            modifier: nil,
            root: "data",
            value: TwParser::Candidate::ArbitraryVariantValue.new(
              value: "disabled"
            )
          )
        ]
      ),
      "bg-red-1/2/3" => nil,
      "bg-[#0088cc]" => TwParser::Candidate::FunctionalCandidate.new(
        important: false,
        modifier: nil,
        raw: "bg-[#0088cc]",
        root: "bg",
        value: TwParser::Candidate::ArbitraryUtilityValue.new(
          data_type: nil,
          value: "#0088cc"
        ),
        variants: []
      ),
      "bg-(--my-color)" => TwParser::Candidate::FunctionalCandidate.new(
        important: false,
        modifier: nil,
        raw: "bg-(--my-color)",
        root: "bg",
        value: TwParser::Candidate::ArbitraryUtilityValue.new(
          data_type: nil,
          value: "var(--my-color)"
        ),
        variants: []
      ),
      "bg-(my-color)" => nil,
      "bg-[color:var(--value)]" => TwParser::Candidate::FunctionalCandidate.new(
        important: false,
        modifier: nil,
        raw: "bg-[color:var(--value)]",
        root: "bg",
        value: TwParser::Candidate::ArbitraryUtilityValue.new(
          data_type: "color",
          value: "var(--value)"
        ),
        variants: []
      ),
      "bg-(color:--my-color)" => TwParser::Candidate::FunctionalCandidate.new(
        important: false,
        modifier: nil,
        raw: "bg-(color:--my-color)",
        root: "bg",
        value: TwParser::Candidate::ArbitraryUtilityValue.new(
          data_type: "color",
          value: "var(--my-color)"
        ),
        variants: []
      ),
      "data-(value):flex" => nil,
      "bg-red-500/(--value)" => TwParser::Candidate::FunctionalCandidate.new(
        important: false,
        modifier: TwParser::Candidate::ArbitraryModifier.new(
          value: "var(--value)"
        ),
        raw: "bg-red-500/(--value)",
        root: "bg",
        value: TwParser::Candidate::NamedUtilityValue.new(
          fraction: nil,
          value: "red-500"
        ),
        variants: []
      ),
      "bg-red-500/(--with_underscore)" => TwParser::Candidate::FunctionalCandidate.new(
        important: false,
        modifier: TwParser::Candidate::ArbitraryModifier.new(
          value: "var(--with_underscore)"
        ),
        raw: "bg-red-500/(--with_underscore)",
        root: "bg",
        value: TwParser::Candidate::NamedUtilityValue.new(
          fraction: nil,
          value: "red-500"
        ),
        variants: []
      ),
      "bg-red-500/(--with_underscore,fallback_value)" => TwParser::Candidate::FunctionalCandidate.new(
        important: false,
        modifier: TwParser::Candidate::ArbitraryModifier.new(
          value: "var(--with_underscore,fallback value)"
        ),
        raw: "bg-red-500/(--with_underscore,fallback_value)",
        root: "bg",
        value: TwParser::Candidate::NamedUtilityValue.new(
          fraction: nil,
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
