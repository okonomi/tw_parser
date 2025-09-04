# frozen_string_literal: true

require "tw_parser/utils/value_parser"

def extract(ast)
  TwParser::Utils::ValueParser.extract(ast)
end

p extract TwParser::Utils::ValueParser.parse("123px")
p extract TwParser::Utils::ValueParser.parse("hello world")
