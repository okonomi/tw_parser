# frozen_string_literal: true

require "tw_parser"

parser = TwParser::Parser.new

puts parser.parse("flex")
puts parser.parse("flex!")
puts parser.parse("hover:flex!")
