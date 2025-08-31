# frozen_string_literal: true

require "tw_parser/value_parser"

RSpec.describe TwParser::ValueParser do
  describe ".parse" do
    def run(input)
      described_class.parse_new(input)
    end

    it "should parse a value" do
      expect(run("123px")).to eq([TwParser::ValueParser::ValueWordNode.new(value: "123px")])
    end

    it "should parse a string value" do
      expect(run("'hello world'")).to eq([TwParser::ValueParser::ValueWordNode.new(value: "'hello world'")])
    end

    it "should parse a list" do
      expect(run("hello world")).to eq(
        [
          TwParser::ValueParser::ValueWordNode.new(value: "hello"),
          TwParser::ValueParser::ValueSeparatorNode.new(value: " "),
          TwParser::ValueParser::ValueWordNode.new(value: "world")
        ]
      )
    end
  end
end
