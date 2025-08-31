# rbs_inline: enabled
# frozen_string_literal: true

require_relative "../value_parser"

module TwParser
  module Candidate
    class ArbitraryValue
      class << self
        #: (String input) -> String
        def decode(input)
          # There are definitely no functions in the input, so bail early
          return convert_underscores_to_whitespace(input) unless input.include?("(")

          ValueParser.parse(input)

          # let ast = ValueParser.parse(input)
          # recursivelyDecodeArbitraryValues(ast)
          # input = ValueParser.toCss(ast)

          # input = addWhitespaceAroundMathOperators(input)

          # return input
        end

        # Convert `_` to ` `, except for escaped underscores `\_` they should be
        # converted to `_` instead.
        def convert_underscores_to_whitespace(input, _skip_underscore_to_space: false)
          escaping = false
          output = +""
          input.each_char do |char|
            output << if char == "_"
                        if escaping
                          escaping = false
                          "_"
                        else
                          " "
                        end
                      elsif char == "\\"
                        escaping = true
                        ""
                      else
                        char
                      end
          end

          output
        end

        #: (String input) -> bool
        def valid?(_input)
          # TODO: implement
          true
        end
      end
    end
  end
end
