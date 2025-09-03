# frozen_string_literal: true

require "tw_parser/value_parser"

RSpec.describe "value_parser" do
  describe ".parse" do
    def run(input)
      TwParser::ValueParser.extract(TwParser::ValueParser.parse_new(input))
    end

    it "should parse a value" do
      expect(run("123px")).to eq(
        [
          { kind: :word, value: "123px" }
        ]
      )
    end

    it "should parse a string value" do
      expect(run("'hello world'")).to eq(
        [
          { kind: :word, value: "'hello world'" }
        ]
      )
    end

    it "should parse a list" do
      expect(run("hello world")).to eq(
        [
          { kind: :word, value: "hello" },
          { kind: :separator, value: " " },
          { kind: :word, value: "world" }
        ]
      )
    end

    it "should parse a string containing parentheses" do
      expect(run("'hello ( world )'")).to eq(
        [
          { kind: :word, value: "'hello ( world )'" }
        ]
      )
    end

    it "should parse a function with no arguments" do
      expect(run("theme()")).to eq(
        [
          { kind: :function, value: "theme", nodes: [] }
        ]
      )
    end

    it "should parse a function with a single argument" do
      expect(run("theme(foo)")).to eq(
        [
          { kind: :function, value: "theme", nodes: [{ kind: :word, value: "foo" }] }
        ]
      )
    end

    it "should parse a function with a single string argument" do
      expect(run("theme('foo')")).to eq(
        [
          { kind: :function, value: "theme", nodes: [{ kind: :word, value: "'foo'" }] }
        ]
      )
    end

    it "should parse a function with multiple arguments" do
      expect(run("theme(foo, bar)")).to eq(
        [
          {
            kind: :function,
            value: "theme",
            nodes: [
              { kind: :word, value: "foo" },
              { kind: :separator, value: ", " },
              { kind: :word, value: "bar" }
            ]
          }
        ]
      )
    end

    it "should parse a function with multiple arguments across lines" do
      expect(run("theme(\n\tfoo,\n\tbar\n)")).to eq(
        [
          {
            kind: :function,
            value: "theme",
            nodes: [
              { kind: :separator, value: "\n\t" },
              { kind: :word, value: "foo" },
              { kind: :separator, value: ",\n\t" },
              { kind: :word, value: "bar" },
              { kind: :separator, value: "\n" }
            ]
          }
        ]
      )
    end

    it "should parse a function with nested arguments" do
      expect(run("theme(foo, theme(bar))")).to eq(
        [
          {
            kind: :function,
            value: "theme",
            nodes: [
              { kind: :word, value: "foo" },
              { kind: :separator, value: ", " },
              { kind: :function, value: "theme", nodes: [{ kind: :word, value: "bar" }] }
            ]
          }
        ]
      )
    end

    it "should parse a function with nested arguments separated by `/`" do
      expect(run("theme(colors.red.500/var(--opacity))")).to eq(
        [
          {
            kind: :function,
            value: "theme",
            nodes: [
              { kind: :word, value: "colors.red.500" },
              { kind: :separator, value: "/" },
              { kind: :function, value: "var", nodes: [{ kind: :word, value: "--opacity" }] }
            ]
          }
        ]
      )
    end

    it "should handle calculations" do
      expect(run("calc((1 + 2) * 3)")).to eq(
        [
          {
            kind: :function,
            value: "calc",
            nodes: [
              {
                kind: :function,
                value: "",
                nodes: [
                  { kind: :word, value: "1" },
                  { kind: :separator, value: " " },
                  { kind: :word, value: "+" },
                  { kind: :separator, value: " " },
                  { kind: :word, value: "2" }
                ]
              },
              { kind: :separator, value: " " },
              { kind: :word, value: "*" },
              { kind: :separator, value: " " },
              { kind: :word, value: "3" }
            ]
          }
        ]
      )
    end

    it "should handle media query params with functions" do
      expect(run("(min-width: 600px) and (max-width:theme(colors.red.500)) and (theme(--breakpoint-sm)<width<=theme(--breakpoint-md))")).to eq(
        [
          {
            kind: :function,
            value: "",
            nodes: [
              { kind: :word, value: "min-width" },
              { kind: :separator, value: ": " },
              { kind: :word, value: "600px" }
            ]
          },
          { kind: :separator, value: " " },
          { kind: :word, value: "and" },
          { kind: :separator, value: " " },
          {
            kind: :function,
            value: "",
            nodes: [
              { kind: :word, value: "max-width" },
              { kind: :separator, value: ":" },
              { kind: :function, value: "theme", nodes: [{ kind: :word, value: "colors.red.500" }] }
            ]
          },
          { kind: :separator, value: " " },
          { kind: :word, value: "and" },
          { kind: :separator, value: " " },
          {
            kind: :function,
            value: "",
            nodes: [
              { kind: :function, value: "theme", nodes: [{ kind: :word, value: "--breakpoint-sm" }] },
              { kind: :separator, value: "<" },
              { kind: :word, value: "width" },
              { kind: :separator, value: "<=" },
              { kind: :function, value: "theme", nodes: [{ kind: :word, value: "--breakpoint-md" }] }
            ]
          }
        ]
      )
    end

    it "should not error when extra `)` was passed" do
      expect(run("calc(1 + 2))")).to eq(
        [
          {
            kind: :function,
            value: "calc",
            nodes: [
              { kind: :word, value: "1" },
              { kind: :separator, value: " " },
              { kind: :word, value: "+" },
              { kind: :separator, value: " " },
              { kind: :word, value: "2" }
            ]
          }
        ]
      )
    end
  end

  describe ".to_css" do
    def to_css(input)
      TwParser::ValueParser.to_css(TwParser::ValueParser.parse_new(input))
    end

    it "should pretty print calculations" do
      expect(to_css("calc((1 + 2) * 3)")).to eq("calc((1 + 2) * 3)")
    end

    it "should pretty print nested function calls" do
      expect(to_css("theme(foo, theme(bar))")).to eq("theme(foo, theme(bar))")
    end

    it "should pretty print media query params with functions" do
      expect(to_css("(min-width: 600px) and (max-width:theme(colors.red.500))")).to eq(
        "(min-width: 600px) and (max-width:theme(colors.red.500))"
      )
    end

    it "preserves multiple spaces" do
      expect(to_css("foo(   bar  )")).to eq("foo(   bar  )")
    end
  end

  describe ".walk" do
    def walk_and_replace(input)
      ast = described_class.extract(described_class.parse_new(input))
      described_class.walk(ast) do |node, context|
        context[:replace_with].call({ kind: :word, value: "64rem" }) if node[:kind] == :function && node[:value] == "theme"
      end
      described_class.to_css(ast)
    end

    it "can be used to replace a function call" do
      expect(walk_and_replace("(min-width: 600px) and (max-width: theme(lg))")).to eq(
        "(min-width: 600px) and (max-width: 64rem)"
      )
    end
  end
end
