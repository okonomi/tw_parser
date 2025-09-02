# frozen_string_literal: true

require "tw_parser"

parser = TwParser::Parser.new

p parser.parse("flex")
p parser.parse("flex!")
p parser.parse("hover:flex!")
p parser.parse("-translate-x-4")
p parser.parse("bg-red-500/50")
p parser.parse("bg-red-500/50!")
p parser.parse("hover:bg-red-500/50")
p parser.parse("[color:red]")
