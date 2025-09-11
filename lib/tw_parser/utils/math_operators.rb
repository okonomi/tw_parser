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

          scan = StringScanner.new(input)
          until scan.eos?
            result << if scan.scan(/\d+[%a-z]*/)
                        scan.matched || ""
                      elsif scan.scan(Regexp.union(*OPERATORS))
                        " #{scan.matched} "
                      else
                        scan.getch || ""
                      end
          end

          result
        end
      end
    end
  end
end
