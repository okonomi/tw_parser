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
            case # rubocop:disable Style/EmptyCaseCondition,Style/ConditionalAssignment
            # function start
            when scanner.scan(/(?:#{MATH_FUNCTIONS.join("|")})\(/)
              # TODO: stack push
              result << scanner.matched.to_s
            # function end
            when scanner.scan(/\)/) # rubocop:disable Lint/DuplicateBranch,Style/RedundantRegexpArgument
              # TODO: stack pop
              result << scanner.matched.to_s
            # value
            when scanner.scan(/\d+[%a-z]*/) # rubocop:disable Lint/DuplicateBranch
              result << scanner.matched.to_s
            # operator
            when scanner.scan(Regexp.union(*OPERATORS))
              result << " #{scanner.matched} "
            else
              result << scanner.getch.to_s
            end
          end

          result
        end
      end
    end
  end
end
