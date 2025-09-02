# frozen_string_literal: true

require "tw_parser/value_parser"

def extract(ast)
  TwParser::ValueParser.extract(ast)
end

p extract TwParser::ValueParser.parse_new("123px")
p extract TwParser::ValueParser.parse_new("hello world")
