# frozen_string_literal: true

require "tw_parser/value_parser"

RSpec.describe TwParser::ValueParser do
  describe ".parse" do
    def run(input)
      described_class.extract(described_class.parse_new(input))
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
  end
end
