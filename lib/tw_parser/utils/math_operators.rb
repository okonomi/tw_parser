# rbs_inline: enabled
# frozen_string_literal: true

require "strscan"

module TwParser
  module Utils
    module MathOperators
      OPERATORS = %w[+ - * /].freeze

      MATH_FUNCTIONS = %w[calc min max clamp].freeze

      NUMBER_SIGNS = %w[+ -].freeze

      class << self
        #: (String input) -> String
        def add_whitespace(input)
          return add_whitespace_v2(input) if ENV["TW_PARSER_MATH_OPS_V2"]

          return input unless input.match?(Regexp.union(*MATH_FUNCTIONS)) || input.include?("var(")

          result = +""
          function_stack = []

          scanner = StringScanner.new(input)
          until scanner.eos?
            case # rubocop:disable Style/EmptyCaseCondition
            # function start (including var)
            when scanner.scan(/(?:#{MATH_FUNCTIONS.join("|")}|var)\(/)
              function_name = scanner.matched.to_s.gsub(/\($/, "")
              function_stack.push(function_name)
              result << scanner.matched.to_s
            # function end
            when scanner.scan(/\)/) # rubocop:disable Style/RedundantRegexpArgument
              function_stack.pop
              result << scanner.matched.to_s
            # value
            when scanner.scan(/\d+[%a-z]*/)
              result << scanner.matched.to_s
            # CSS variables (--name)
            when scanner.scan(/--[a-z][a-z0-9-]*/)
              result << scanner.matched.to_s
            # comma (add space after comma in function arguments, except in var())
            when scanner.scan(/,/) # rubocop:disable Style/RedundantRegexpArgument
              result << if function_stack.last == "var"
                          ","
                        else
                          ", "
                        end
            # operator
            when scanner.scan(Regexp.union(*OPERATORS))
              operator = scanner.matched.to_s
              # check if this is a sign (+ or -) after an operator or at the start of calc
              if NUMBER_SIGNS.include?(operator) && result.end_with?(" + ", " - ", " * ", " / ", "(")
                result << operator
              else
                # add space before operator if not already present
                result << " " unless result.end_with?(" ")
                result << operator
                result << " "
              end
            else
              result << scanner.getch.to_s
            end
          end

          result
        end

        #: (String input) -> String
        def add_whitespace_v2(input)
          scanner = StringScanner.new(input)
          value_pos = nil
          last_value_pos = nil

          until scanner.eos?
            char = scanner.getch #: String

            # Track if we see a number followed by a unit, then we know for sure that
            # this is not a function call.
            if char.between?("0", "9")
              value_pos = scanner.pos

            # If we saw a number before, and we see normal a-z character, then we
            # assume this is a value such as `123px`
            elsif value_pos && (char == "%" || char.between?("a", "z") || char.between?("A", "Z")) # rubocop:disable Lint/DuplicateBranch
              value_pos = scanner.pos

            # Once we see something else, we reset the value position
            else
              last_value_pos = value_pos
              value_pos = nil
            end

            puts "char: #{char.inspect}, pos: #{scanner.pos}, value_pos: #{value_pos}, last_value_pos: #{last_value_pos}" if ENV["TW_PARSER_MATH_OPS_DEBUG"]
          end

          ""
        end
      end
    end
  end
end
