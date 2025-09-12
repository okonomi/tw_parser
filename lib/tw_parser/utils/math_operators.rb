# rbs_inline: enabled
# frozen_string_literal: true

require "strscan"

module TwParser
  module Utils
    module MathOperators
      OPERATORS = %w[+ - * /].freeze

      MATH_FUNCTIONS = %w[calc].freeze

      class << self
        #: (String input) -> String
        def add_whitespace(input)
          return input unless input.match?(Regexp.union(*MATH_FUNCTIONS))

          result = +""

          scanner = StringScanner.new(input)
          until scanner.eos?
            result << if scanner.scan(/\d+[%a-z]*/)
                        scanner.matched || ""
                      elsif scanner.scan(Regexp.union(*OPERATORS))
                        " #{scanner.matched} "
                      else
                        scanner.getch || ""
                      end
          end

          result
        end
      end
    end
  end
end
