# frozen_string_literal: true

require "tw_parser"

parser = TwParser::Parser.new

p parser.parse("flex")
p parser.parse("flex!")
p parser.parse("hover:flex!")
