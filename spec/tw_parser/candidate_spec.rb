# frozen_string_literal: true

require_relative "../../lib/tw_parser/candidate/util"

RSpec.describe TwParser::Candidate::Parser do
  describe "#parse", :aggregate_failures do
    def run(candidate, utilities: nil, variants: nil, prefix: nil)
      utilities ||= TwParser::Utilities.new
      variants ||= TwParser::Variants.new

      parser = described_class.new

      candidate = parser.parse(candidate, utilities:, variants:, prefix:)
      return [] if candidate.nil?

      [TwParser::Candidate::Util.extract_candidate_info(candidate)]
    end

    it "should skip unknown utilities" do
      expect(run("unknown-utility")).to eq([])
    end

    it "should skip unknown variants" do
      expect(run("unknown-variant:flex")).to eq([])
    end

    it "should parse a simple utility" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      expect(run("flex", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "flex",
            root: "flex",
            variants: []
          }
        ]
      )
    end

    it "should parse a simple utility that should be important" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      expect(run("flex!", utilities: utilities)).to eq(
        [
          {
            important: true,
            kind: :static,
            raw: "flex!",
            root: "flex",
            variants: []
          }
        ]
      )
    end

    it "should parse a simple utility that can be negative" do
      utilities = TwParser::Utilities.new
      utilities.functional("-translate-x") { [] }

      expect(run("-translate-x-4", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "-translate-x-4",
            root: "-translate-x",
            value: {
              fraction: nil,
              kind: :named,
              value: "4"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a simple utility with a variant" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.static("hover") {}

      expect(run("hover:flex", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "hover:flex",
            root: "flex",
            variants: [
              {
                kind: :static,
                root: "hover"
              }
            ]
          }
        ]
      )
    end

    it "should parse a simple utility with stacked variants" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.static("hover") {}
      variants.static("focus") {}

      expect(run("focus:hover:flex", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "focus:hover:flex",
            root: "flex",
            variants: [
              {
                kind: :static,
                root: "hover"
              },
              {
                kind: :static,
                root: "focus"
              }
            ]
          }
        ]
      )
    end

    it "should parse a simple utility with an arbitrary variant" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      expect(run("[&_p]:flex", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "[&_p]:flex",
            root: "flex",
            variants: [
              {
                kind: :arbitrary,
                relative: false,
                selector: "& p"
              }
            ]
          }
        ]
      )
    end

    it "should parse an arbitrary variant using the automatic var shorthand" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.functional("supports") {}

      expect(run("supports-(--test):flex", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "supports-(--test):flex",
            root: "flex",
            variants: [
              {
                kind: :functional,
                modifier: nil,
                root: "supports",
                value: {
                  kind: :arbitrary,
                  value: "var(--test)"
                }
              }
            ]
          }
        ]
      )
    end

    it "should parse a simple utility with a parameterized variant" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.functional("data") {}

      expect(run("data-[disabled]:flex", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "data-[disabled]:flex",
            root: "flex",
            variants: [
              {
                kind: :functional,
                modifier: nil,
                root: "data",
                value: {
                  kind: :arbitrary,
                  value: "disabled"
                }
              }
            ]
          }
        ]
      )
    end

    it "should parse compound variants with an arbitrary value as an arbitrary variant" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.compound("group", TwParser::Variants::COMPOUND_STYLE_RULES) {}

      expect(run("group-[&_p]/parent-name:flex", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "group-[&_p]/parent-name:flex",
            root: "flex",
            variants: [
              {
                kind: :compound,
                modifier: {
                  kind: :named,
                  value: "parent-name"
                },
                root: "group",
                variant: {
                  kind: :arbitrary,
                  relative: false,
                  selector: "& p"
                }
              }
            ]
          }
        ]
      )
    end

    it "should parse a simple utility with a parameterized variant and a modifier" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.compound("group", TwParser::Variants::COMPOUND_STYLE_RULES) {}
      variants.functional("aria") {}

      expect(run("group-aria-[disabled]/parent-name:flex", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "group-aria-[disabled]/parent-name:flex",
            root: "flex",
            variants: [
              {
                kind: :compound,
                modifier: {
                  kind: :named,
                  value: "parent-name"
                },
                root: "group",
                variant: {
                  kind: :functional,
                  modifier: nil,
                  root: "aria",
                  value: {
                    kind: :arbitrary,
                    value: "disabled"
                  }
                }
              }
            ]
          }
        ]
      )
    end

    it "should parse compound group with itself group-group-*" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.static("hover") {}
      variants.compound("group", TwParser::Variants::COMPOUND_STYLE_RULES) {}

      expect(run("group-group-group-hover/parent-name:flex", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "group-group-group-hover/parent-name:flex",
            root: "flex",
            variants: [
              {
                kind: :compound,
                modifier: {
                  kind: :named,
                  value: "parent-name"
                },
                root: "group",
                variant: {
                  kind: :compound,
                  modifier: nil,
                  root: "group",
                  variant: {
                    kind: :compound,
                    modifier: nil,
                    root: "group",
                    variant: {
                      kind: :static,
                      root: "hover"
                    }
                  }
                }
              }
            ]
          }
        ]
      )
    end

    it "should parse a simple utility with an arbitrary media variant" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      expect(run("[@media(width>=123px)]:flex", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "[@media(width>=123px)]:flex",
            root: "flex",
            variants: [
              {
                kind: :arbitrary,
                relative: false,
                selector: "@media(width>=123px)"
              }
            ]
          }
        ]
      )
    end

    it "should skip arbitrary variants where @media and other arbitrary variants are combined" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      expect(run("[@media(width>=123px){&:hover}]:flex", utilities: utilities)).to eq([])
    end

    it "should parse a utility with a modifier" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-red-500/50", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: {
              kind: :named,
              value: "50"
            },
            raw: "bg-red-500/50",
            root: "bg",
            value: {
              fraction: "red-500/50",
              kind: :named,
              value: "red-500"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a utility with an arbitrary modifier" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-red-500/[50%]", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: {
              kind: :arbitrary,
              value: "50%"
            },
            raw: "bg-red-500/[50%]",
            root: "bg",
            value: {
              fraction: nil,
              kind: :named,
              value: "red-500"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a utility with a modifier that is important" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-red-500/50!", utilities: utilities)).to eq(
        [
          {
            important: true,
            kind: :functional,
            modifier: {
              kind: :named,
              value: "50"
            },
            raw: "bg-red-500/50!",
            root: "bg",
            value: {
              fraction: "red-500/50",
              kind: :named,
              value: "red-500"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a utility with a modifier and a variant" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      variants = TwParser::Variants.new
      variants.static("hover") {}

      expect(run("hover:bg-red-500/50", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: {
              kind: :named,
              value: "50"
            },
            raw: "hover:bg-red-500/50",
            root: "bg",
            value: {
              fraction: "red-500/50",
              kind: :named,
              value: "red-500"
            },
            variants: [
              {
                kind: :static,
                root: "hover"
              }
            ]
          }
        ]
      )
    end

    it "should not parse a partial utility" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }
      utilities.functional("bg") { [] }

      expect(run("flex-", utilities: utilities)).to eq([])
      expect(run("bg-", utilities: utilities)).to eq([])
    end

    it "should not parse static utilities with a modifier" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      expect(run("flex/foo", utilities: utilities)).to eq([])
    end

    it "should not parse static utilities with multiple modifiers" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      expect(run("flex/foo/bar", utilities: utilities)).to eq([])
    end

    it "should not parse functional utilities with multiple modifiers" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-red-1/2/3", utilities: utilities)).to eq([])
    end

    it "should parse a utility with an arbitrary value" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-[#0088cc]", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "bg-[#0088cc]",
            root: "bg",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "#0088cc"
            },
            variants: []
          }
        ]
      )
    end

    it "should not parse a utility with an incomplete arbitrary value" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-[#0088cc", utilities: utilities)).to eq([])
    end

    it "should parse a utility with an arbitrary value with parens" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-(--my-color)", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "bg-(--my-color)",
            root: "bg",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "var(--my-color)"
            },
            variants: []
          }
        ]
      )
    end

    it "should not parse a utility with an arbitrary value with parens that does not start with --" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-(my-color)", utilities: utilities)).to eq([])
    end

    it "should parse a utility with an arbitrary value including a typehint" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-[color:var(--value)]", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "bg-[color:var(--value)]",
            root: "bg",
            value: {
              data_type: "color",
              kind: :arbitrary,
              value: "var(--value)"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a utility with an arbitrary value with parens including a typehint" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-(color:--my-color)", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "bg-(color:--my-color)",
            root: "bg",
            value: {
              data_type: "color",
              kind: :arbitrary,
              value: "var(--my-color)"
            },
            variants: []
          }
        ]
      )
    end

    it "should not parse a utility with an arbitrary value with parens including a typehint that does not start with --" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-(color:my-color)", utilities: utilities)).to eq([])
    end

    it "should parse a utility with an arbitrary value with parens and a fallback" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-(color:--my-color,#0088cc)", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "bg-(color:--my-color,#0088cc)",
            root: "bg",
            value: {
              data_type: "color",
              kind: :arbitrary,
              value: "var(--my-color,#0088cc)"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a utility with an arbitrary value with a modifier" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-[#0088cc]/50", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: {
              kind: :named,
              value: "50"
            },
            raw: "bg-[#0088cc]/50",
            root: "bg",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "#0088cc"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a utility with an arbitrary value with an arbitrary modifier" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-[#0088cc]/[50%]", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: {
              kind: :arbitrary,
              value: "50%"
            },
            raw: "bg-[#0088cc]/[50%]",
            root: "bg",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "#0088cc"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a utility with an arbitrary value that is important" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-[#0088cc]!", utilities: utilities)).to eq(
        [
          {
            important: true,
            kind: :functional,
            modifier: nil,
            raw: "bg-[#0088cc]!",
            root: "bg",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "#0088cc"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a utility with an implicit variable as the arbitrary value" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-[var(--value)]", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "bg-[var(--value)]",
            root: "bg",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "var(--value)"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a utility with an implicit variable as the arbitrary value that is important" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-[var(--value)]!", utilities: utilities)).to eq(
        [
          {
            important: true,
            kind: :functional,
            modifier: nil,
            raw: "bg-[var(--value)]!",
            root: "bg",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "var(--value)"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a utility with an explicit variable as the arbitrary value" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-[var(--value)]", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "bg-[var(--value)]",
            root: "bg",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "var(--value)"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a utility with an explicit variable as the arbitrary value that is important" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-[var(--value)]!", utilities: utilities)).to eq(
        [
          {
            important: true,
            kind: :functional,
            modifier: nil,
            raw: "bg-[var(--value)]!",
            root: "bg",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "var(--value)"
            },
            variants: []
          }
        ]
      )
    end

    it "should not parse invalid arbitrary values" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      candidates = [
        "bg-red-[#0088cc]",
        "bg-red[#0088cc]",
        "bg-red-[color:var(--value)]",
        "bg-red[color:var(--value)]",
        "bg-red-[#0088cc]/50",
        "bg-red[#0088cc]/50",
        "bg-red-[#0088cc]/[50%]",
        "bg-red[#0088cc]/[50%]",
        "bg-red-[#0088cc]!",
        "bg-red[#0088cc]!",
        "bg-red-[var(--value)]",
        "bg-red[var(--value)]",
        "bg-red-[var(--value)]!",
        "bg-red[var(--value)]!"
      ]

      candidates.each do |candidate|
        expect(run(candidate, utilities: utilities)).to eq([])
      end
    end

    it "should not parse invalid arbitrary values in variants" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.functional("data") {}

      [
        "data-foo-[#0088cc]:flex",
        "data-foo[#0088cc]:flex",

        "data-foo-[color:var(--value)]:flex",
        "data-foo[color:var(--value)]:flex",

        "data-foo-[#0088cc]/50:flex",
        "data-foo[#0088cc]/50:flex",

        "data-foo-[#0088cc]/[50%]:flex",
        "data-foo[#0088cc]/[50%]:flex",

        "data-foo-[#0088cc]:flex!",
        "data-foo[#0088cc]:flex!",

        "data-foo-[var(--value)]:flex",
        "data-foo[var(--value)]:flex",

        "data-foo-[var(--value)]:flex!",
        "data-foo[var(--value)]:flex!",

        "data-foo-(color:--value):flex",
        "data-foo(color:--value):flex",

        "data-foo-(color:--value)/50:flex",
        "data-foo(color:--value)/50:flex",

        "data-foo-(color:--value)/(--mod):flex",
        "data-foo(color:--value)/(--mod):flex",

        "data-foo-(color:--value)/(number:--mod):flex",
        "data-foo(color:--value)/(number:--mod):flex",

        "data-foo-(--value):flex",
        "data-foo(--value):flex",

        "data-foo-(--value)/50:flex",
        "data-foo(--value)/50:flex",

        "data-foo-(--value)/(--mod):flex",
        "data-foo(--value)/(--mod):flex",

        "data-foo-(--value)/(number:--mod):flex",
        "data-foo(--value)/(number:--mod):flex",

        "data-(value):flex"
      ].each do |candidate|
        expect(run(candidate, utilities: utilities, variants: variants)).to eq([])
      end
    end

    it "should parse a utility with an implicit variable as the modifier" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-red-500/[var(--value)]", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: {
              kind: :arbitrary,
              value: "var(--value)"
            },
            raw: "bg-red-500/[var(--value)]",
            root: "bg",
            value: {
              fraction: nil,
              kind: :named,
              value: "red-500"
            },
            variants: []
          }
        ]
      )
    end

    it "should properly decode escaped underscores but not convert underscores to spaces for CSS variables in arbitrary positions" do
      utilities = TwParser::Utilities.new
      utilities.functional("flex") { [] }

      variants = TwParser::Variants.new
      variants.functional("supports") {}

      expect(run("flex-(--\\_foo)", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "flex-(--\\_foo)",
            root: "flex",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "var(--_foo)"
            },
            variants: []
          }
        ]
      )

      expect(run("flex-(--_foo)", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "flex-(--_foo)",
            root: "flex",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "var(--_foo)"
            },
            variants: []
          }
        ]
      )

      expect(run("flex-[var(--\\_foo)]", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "flex-[var(--\\_foo)]",
            root: "flex",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "var(--_foo)"
            },
            variants: []
          }
        ]
      )

      expect(run("flex-[var(--_foo)]", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "flex-[var(--_foo)]",
            root: "flex",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "var(--_foo)"
            },
            variants: []
          }
        ]
      )

      expect(run("flex-[calc(var(--\\_foo)*0.2)]", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "flex-[calc(var(--\\_foo)*0.2)]",
            root: "flex",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "calc(var(--_foo) * 0.2)"
            },
            variants: []
          }
        ]
      )

      expect(run("flex-[calc(var(--_foo)*0.2)]", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "flex-[calc(var(--_foo)*0.2)]",
            root: "flex",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "calc(var(--_foo) * 0.2)"
            },
            variants: []
          }
        ]
      )

      expect(run("flex-[calc(0.2*var(--\\_foo)]", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "flex-[calc(0.2*var(--\\_foo)]",
            root: "flex",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "calc(0.2 * var(--_foo))"
            },
            variants: []
          }
        ]
      )

      expect(run("flex-[calc(0.2*var(--_foo)]", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "flex-[calc(0.2*var(--_foo)]",
            root: "flex",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "calc(0.2 * var(-- foo))"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a utility with an implicit variable as the modifier using the shorthand" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-red-500/(--value)", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: {
              kind: :arbitrary,
              value: "var(--value)"
            },
            raw: "bg-red-500/(--value)",
            root: "bg",
            value: {
              fraction: nil,
              kind: :named,
              value: "red-500"
            },
            variants: []
          }
        ]
      )

      expect(run("bg-red-500/(--with_underscore)", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: {
              kind: :arbitrary,
              value: "var(--with_underscore)"
            },
            raw: "bg-red-500/(--with_underscore)",
            root: "bg",
            value: {
              fraction: nil,
              kind: :named,
              value: "red-500"
            },
            variants: []
          }
        ]
      )

      expect(run("bg-red-500/(--with_underscore,fallback_value)", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: {
              kind: :arbitrary,
              value: "var(--with_underscore,fallback value)"
            },
            raw: "bg-red-500/(--with_underscore,fallback_value)",
            root: "bg",
            value: {
              fraction: nil,
              kind: :named,
              value: "red-500"
            },
            variants: []
          }
        ]
      )

      expect(run("bg-(--a_b,c_d_var(--e_f,g_h))/(--i_j,k_l_var(--m_n,o_p))", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: {
              kind: :arbitrary,
              value: "var(--i_j,k l var(--m_n,o p))"
            },
            raw: "bg-(--a_b,c_d_var(--e_f,g_h))/(--i_j,k_l_var(--m_n,o_p))",
            root: "bg",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "var(--a_b,c d var(--e_f,g h))"
            },
            variants: []
          }
        ]
      )
    end

    it "should not parse an invalid arbitrary shorthand modifier" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-red-500/()", utilities: utilities)).to eq([])
      expect(run("bg-red-500/(_--)", utilities: utilities)).to eq([])
      expect(run("bg-red-500/(_--x)", utilities: utilities)).to eq([])
      expect(run("bg-red-500/(--x;--y)", utilities: utilities)).to eq([])
      expect(run("bg-red-500/(--x:{foo:bar})", utilities: utilities)).to eq([])

      expect(run("bg-red-500/(--x)", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: {
              kind: :arbitrary,
              value: "var(--x)"
            },
            raw: "bg-red-500/(--x)",
            root: "bg",
            value: {
              fraction: nil,
              kind: :named,
              value: "red-500"
            },
            variants: []
          }
        ]
      )
    end

    it "should not parse an invalid arbitrary shorthand value" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-()", utilities: utilities)).to eq([])
      expect(run("bg-(_--)", utilities: utilities)).to eq([])
      expect(run("bg-(_--x)", utilities: utilities)).to eq([])
      expect(run("bg-(--x;--y)", utilities: utilities)).to eq([])
      expect(run("bg-(--x:{foo:bar})", utilities: utilities)).to eq([])

      expect(run("bg-(--x)", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "bg-(--x)",
            root: "bg",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "var(--x)"
            },
            variants: []
          }
        ]
      )
    end

    it "should not parse a utility with an implicit invalid variable as the modifier using the shorthand" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-red-500/(value)", utilities: utilities)).to eq([])
    end

    it "should parse a utility with an implicit variable as the modifier that is important" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-red-500/[var(--value)]!", utilities: utilities)).to eq(
        [
          {
            important: true,
            kind: :functional,
            modifier: {
              kind: :arbitrary,
              value: "var(--value)"
            },
            raw: "bg-red-500/[var(--value)]!",
            root: "bg",
            value: {
              fraction: nil,
              kind: :named,
              value: "red-500"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a utility with an explicit variable as the modifier" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-red-500/[var(--value)]", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: {
              kind: :arbitrary,
              value: "var(--value)"
            },
            raw: "bg-red-500/[var(--value)]",
            root: "bg",
            value: {
              fraction: nil,
              kind: :named,
              value: "red-500"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse a utility with an explicit variable as the modifier that is important" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-red-500/[var(--value)]!", utilities: utilities)).to eq(
        [
          {
            important: true,
            kind: :functional,
            modifier: {
              kind: :arbitrary,
              value: "var(--value)"
            },
            raw: "bg-red-500/[var(--value)]!",
            root: "bg",
            value: {
              fraction: nil,
              kind: :named,
              value: "red-500"
            },
            variants: []
          }
        ]
      )
    end

    it "should not parse a partial variant" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.static("open") {}
      variants.functional("data") {}

      expect(run("open-:flex", utilities: utilities, variants: variants)).to eq([])
      expect(run("data-:flex", utilities: utilities, variants: variants)).to eq([])
    end

    it "should parse a static variant starting with @" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.static("@lg") {}

      expect(run("@lg:flex", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "@lg:flex",
            root: "flex",
            variants: [
              {
                kind: :static,
                root: "@lg"
              }
            ]
          }
        ]
      )
    end

    it "should parse a functional variant with a modifier" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.functional("foo") {}

      expect(run("foo-bar/50:flex", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "foo-bar/50:flex",
            root: "flex",
            variants: [
              {
                kind: :functional,
                modifier: {
                  kind: :named,
                  value: "50"
                },
                root: "foo",
                value: {
                  kind: :named,
                  value: "bar"
                }
              }
            ]
          }
        ]
      )
    end

    it "should parse a functional variant starting with @" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.functional("@") {}

      expect(run("@lg:flex", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "@lg:flex",
            root: "flex",
            variants: [
              {
                kind: :functional,
                modifier: nil,
                root: "@",
                value: {
                  kind: :named,
                  value: "lg"
                }
              }
            ]
          }
        ]
      )
    end

    it "should parse a functional variant starting with @ that has a hyphen" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.functional("@") {}

      expect(run("@foo-bar:flex", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "@foo-bar:flex",
            root: "flex",
            variants: [
              {
                kind: :functional,
                modifier: nil,
                root: "@",
                value: {
                  kind: :named,
                  value: "foo-bar"
                }
              }
            ]
          }
        ]
      )
    end

    it "should parse a functional variant starting with @ and a modifier" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.functional("@") {}

      expect(run("@lg/name:flex", utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "@lg/name:flex",
            root: "flex",
            variants: [
              {
                kind: :functional,
                modifier: {
                  kind: :named,
                  value: "name"
                },
                root: "@",
                value: {
                  kind: :named,
                  value: "lg"
                }
              }
            ]
          }
        ]
      )
    end

    it "should replace _ with space" do
      utilities = TwParser::Utilities.new
      utilities.functional("content") { [] }

      expect(run('content-["hello_world"]', utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: 'content-["hello_world"]',
            root: "content",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: '"hello world"'
            },
            variants: []
          }
        ]
      )
    end

    it "should not replace \\_ with space (when it is escaped)" do
      utilities = TwParser::Utilities.new
      utilities.functional("content") { [] }

      expect(run('content-["hello\\_world"]', utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: 'content-["hello\\_world"]',
            root: "content",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: '"hello_world"'
            },
            variants: []
          }
        ]
      )
    end

    it "should not replace _ inside of url()" do
      utilities = TwParser::Utilities.new
      utilities.functional("bg") { [] }

      expect(run("bg-[no-repeat_url(https://example.com/some_page)]", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "bg-[no-repeat_url(https://example.com/some_page)]",
            root: "bg",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "no-repeat url(https://example.com/some_page)"
            },
            variants: []
          }
        ]
      )
    end

    it "should not replace _ in the first argument to var()" do
      utilities = TwParser::Utilities.new
      utilities.functional("ml") { [] }

      expect(run("ml-[var(--spacing-1_5,_var(--spacing-2_5,_1rem))]", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "ml-[var(--spacing-1_5,_var(--spacing-2_5,_1rem))]",
            root: "ml",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "var(--spacing-1_5, var(--spacing-2_5, 1rem))"
            },
            variants: []
          }
        ]
      )
    end

    it "should not replace _ in the first argument to theme()" do
      utilities = TwParser::Utilities.new
      utilities.functional("ml") { [] }

      expect(run("ml-[theme(--spacing-1_5,_theme(--spacing-2_5,_1rem))]", utilities: utilities)).to eq(
        [
          {
            important: false,
            kind: :functional,
            modifier: nil,
            raw: "ml-[theme(--spacing-1_5,_theme(--spacing-2_5,_1rem))]",
            root: "ml",
            value: {
              data_type: nil,
              kind: :arbitrary,
              value: "theme(--spacing-1_5, theme(--spacing-2_5, 1rem))"
            },
            variants: []
          }
        ]
      )
    end

    it "should parse arbitrary properties" do
      expect(run("[color:red]")).to eq(
        [
          {
            important: false,
            kind: :arbitrary,
            modifier: nil,
            property: "color",
            raw: "[color:red]",
            value: "red",
            variants: []
          }
        ]
      )
    end

    it "should parse arbitrary properties with a modifier" do
      expect(run("[color:red]/50")).to eq(
        [
          {
            important: false,
            kind: :arbitrary,
            modifier: {
              kind: :named,
              value: "50"
            },
            property: "color",
            raw: "[color:red]/50",
            value: "red",
            variants: []
          }
        ]
      )
    end

    it "should skip arbitrary properties that start with an uppercase letter" do
      expect(run("[Color:red]")).to eq([])
    end

    it "should skip arbitrary properties that do not have a property and value" do
      expect(run("[color]")).to eq([])
    end

    it "should parse arbitrary properties that are important" do
      expect(run("[color:red]!")).to eq(
        [
          {
            important: true,
            kind: :arbitrary,
            modifier: nil,
            property: "color",
            raw: "[color:red]!",
            value: "red",
            variants: []
          }
        ]
      )
    end

    it "should parse arbitrary properties with a variant" do
      variants = TwParser::Variants.new
      variants.static("hover") {}

      expect(run("hover:[color:red]", variants: variants)).to eq(
        [
          {
            important: false,
            kind: :arbitrary,
            modifier: nil,
            property: "color",
            raw: "hover:[color:red]",
            value: "red",
            variants: [
              {
                kind: :static,
                root: "hover"
              }
            ]
          }
        ]
      )
    end

    it "should parse arbitrary properties with stacked variants" do
      variants = TwParser::Variants.new
      variants.static("hover") {}
      variants.static("focus") {}

      expect(run("focus:hover:[color:red]", variants: variants)).to eq(
        [
          {
            important: false,
            kind: :arbitrary,
            modifier: nil,
            property: "color",
            raw: "focus:hover:[color:red]",
            value: "red",
            variants: [
              {
                kind: :static,
                root: "hover"
              },
              {
                kind: :static,
                root: "focus"
              }
            ]
          }
        ]
      )
    end

    it "should parse arbitrary properties that are important and using stacked arbitrary variants" do
      expect(run("[@media(width>=123px)]:[&_p]:[color:red]!")).to eq(
        [
          {
            important: true,
            kind: :arbitrary,
            modifier: nil,
            property: "color",
            raw: "[@media(width>=123px)]:[&_p]:[color:red]!",
            value: "red",
            variants: [
              {
                kind: :arbitrary,
                relative: false,
                selector: "& p"
              },
              {
                kind: :arbitrary,
                relative: false,
                selector: "@media(width>=123px)"
              }
            ]
          }
        ]
      )
    end

    it "should not parse compound group with a non-compoundable variant" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.compound("group", TwParser::Variants::COMPOUND_STYLE_RULES) {}

      expect(run("group-*:flex", utilities: utilities, variants: variants)).to eq([])
    end

    it "should parse a variant containing an arbitrary string with unbalanced parens, brackets, curlies and other quotes" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.functional("string") {}

      expect(run(%q`string-['}[("\'']:flex`, utilities: utilities, variants: variants)).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: %q`string-['}[("\'']:flex`,
            root: "flex",
            variants: [
              {
                kind: :functional,
                modifier: nil,
                root: "string",
                value: {
                  kind: :arbitrary,
                  value: %q`'}[("\''`
                }
              }
            ]
          }
        ]
      )
    end

    it "should parse candidates with a prefix" do
      utilities = TwParser::Utilities.new
      utilities.static("flex") { [] }

      variants = TwParser::Variants.new
      variants.static("hover") {}

      expect(run("flex", utilities: utilities, variants: variants, prefix: "tw")).to eq([])

      expect(run("tw:flex", utilities: utilities, variants: variants, prefix: "tw")).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "tw:flex",
            root: "flex",
            variants: []
          }
        ]
      )

      expect(run("tw:hover:flex", utilities: utilities, variants: variants, prefix: "tw")).to eq(
        [
          {
            important: false,
            kind: :static,
            raw: "tw:hover:flex",
            root: "flex",
            variants: [
              {
                kind: :static,
                root: "hover"
              }
            ]
          }
        ]
      )
    end

    [
      # Empty arbitrary value
      "bg-[]",
      "bg-()",
      # — Tricking the parser with a space is not allowed
      "bg-[_]",
      "bg-(_)",

      # Empty arbitrary value, with typehint
      "bg-[color:]",
      "bg-(color:)",
      # — Tricking the parser with a space is not allowed
      "bg-[color:_]",
      "bg-(color:_)",

      # Empty arbitrary modifier
      "bg-red-500/[]",
      "bg-red-500/()",
      # — Tricking the parser with a space is not allowed
      "bg-red-500/[_]",
      "bg-red-500/(_)",

      # Empty arbitrary modifier for arbitrary properties
      "[color:red]/[]",
      "[color:red]/()",
      # — Tricking the parser with a space is not allowed
      "[color:red]/[_]",
      "[color:red]/(_)",

      # Empty arbitrary value and modifier
      "bg-[]/[]",
      "bg-()/[]",
      "bg-[]/()",
      "bg-()/()",
      # — Tricking the parser with a space is not allowed
      "bg-[_]/[]",
      "bg-(_)/[]",
      "bg-[_]/()",
      "bg-(_)/()",
      "bg-[]/[_]",
      "bg-()/[_]",
      "bg-[]/(_)",
      "bg-()/(_)",
      "bg-[_]/[_]",
      "bg-(_)/[_]",
      "bg-[_]/(_)",
      "bg-(_)/(_)",

      # Functional variants
      # Empty arbitrary value in variant
      "data-[]:flex",
      "data-():flex",
      # — Tricking the parser with a space is not allowed
      "data-[_]:flex",
      "data-(_):flex",

      # Empty arbitrary modifier in variant
      "data-foo/[]:flex",
      "data-foo/():flex",
      # — Tricking the parser with a space is not allowed
      "data-foo/[_]:flex",
      "data-foo/(_):flex",

      # Empty arbitrary value and modifier in variant
      "data-[]/[]:flex",
      "data-()/[]:flex",
      "data-[]/():flex",
      "data-()/():flex",
      # — Tricking the parser with a space is not allowed
      "data-[_]/[]:flex",
      "data-(_)/[]:flex",
      "data-[_]/():flex",
      "data-(_)/():flex",
      "data-[]/[_]:flex",
      "data-()/[_]:flex",
      "data-[]/(_):flex",
      "data-()/(_):flex",
      "data-[_]/[_]:flex",
      "data-(_)/[_]:flex",
      "data-[_]/(_):flex",
      "data-(_)/(_):flex",

      # Compound variants
      # Empty arbitrary value in variant
      "group-data-[]:flex",
      "group-data-():flex",
      # — Tricking the parser with a space is not allowed
      "group-data-[_]:flex",
      "group-data-(_):flex",

      # Empty arbitrary modifier in variant
      "group-data-foo/[]:flex",
      "group-data-foo/():flex",
      # — Tricking the parser with a space is not allowed
      "group-data-foo/[_]:flex",
      "group-data-foo/(_):flex",

      # Empty arbitrary value and modifier in variant
      "group-data-[]/[]:flex",
      "group-data-()/[]:flex",
      "group-data-[]/():flex",
      "group-data-()/():flex",
      # — Tricking the parser with a space is not allowed
      "group-data-[_]/[]:flex",
      "group-data-(_)/[]:flex",
      "group-data-[_]/():flex",
      "group-data-(_)/():flex",
      "group-data-[]/[_]:flex",
      "group-data-()/[_]:flex",
      "group-data-[]/(_):flex",
      "group-data-()/(_):flex",
      "group-data-[_]/[_]:flex",
      "group-data-(_)/[_]:flex",
      "group-data-[_]/(_):flex",
      "group-data-(_)/(_):flex"
    ].each do |raw_candidate|
      it "should not parse invalid empty arbitrary values: #{raw_candidate}" do
        utilities = TwParser::Utilities.new
        utilities.static("flex") { [] }
        utilities.functional("bg") { [] }

        variants = TwParser::Variants.new
        variants.functional("data") {}
        variants.compound("group", TwParser::Variants::COMPOUND_STYLE_RULES) {}

        expect(run(raw_candidate, utilities: utilities, variants: variants)).to eq([])
      end
    end

    [
      # Arbitrary properties with `;` or `}`
      "[color:red;color:blue]",
      "[color:red}html{color:blue]",

      # Arbitrary values that end the declaration
      "bg-[red;color:blue]",

      # Arbitrary values that end the block
      "bg-[red}html{color:blue]",

      # Arbitrary variants that end the block
      "[&{color:red}]:flex",

      # Arbitrary variant values that end the block
      "data-[a]{color:red}foo[a]:flex"
    ].each do |raw_candidate|
      it "should not parse invalid arbitrary values: #{raw_candidate}" do
        utilities = TwParser::Utilities.new
        utilities.static("flex") { [] }
        utilities.functional("bg") { [] }

        variants = TwParser::Variants.new
        variants.functional("data") {}
        variants.compound("group", TwParser::Variants::COMPOUND_STYLE_RULES) {}

        expect(run(raw_candidate, utilities: utilities, variants: variants)).to eq([])
      end
    end
  end
end
