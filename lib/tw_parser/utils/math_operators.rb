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
          # Bail early if there are no math functions in the input
          return input unless input.match?(Regexp.union(*MATH_FUNCTIONS))

          result = +""
          formattable = [] #: Array[TrueClass | FalseClass]

          value_pos = nil #: Integer | nil
          last_value_pos = nil #: Integer | nil

          scanner = StringScanner.new(input)
          until scanner.eos?
            char = scanner.getch #: String

            # Track if we see a number followed by a unit, then we know for sure that
            # this is not a function call.
            if char.between?("0", "9")
              value_pos = scanner.pos

            # If we saw a number before, and we see normal a-z character, then we
            # assume this is a value such as `123px`
            elsif value_pos && (char == "%" || char.between?("a", "z") || char.between?("A", "Z"))
              value_pos = scanner.pos

            # Once we see something else, we reset the value position
            else
              last_value_pos = value_pos
              value_pos = nil
            end

            # Determine if we're inside a math function
            if char == "("
              result << char

              # Scan backwards to determine the function name. This assumes math
              # functions are named with lowercase alphanumeric characters.
              start = scanner.pos - 1

              j = scanner.pos - 2
              while j >= 0
                inner = input[j]
                if inner&.between?("0", "9")
                  start = j
                elsif inner&.between?("a", "z")
                  start = j
                else
                  break
                end

                j -= 1
              end

              fn = input.slice(start...(scanner.pos - 1))

              # This is a known math function so start formatting
              if MATH_FUNCTIONS.include?(fn)
                formattable.unshift(true)
                next
              end

              # We've encountered nested parens inside a math function, record that and
              # keep formatting until we've closed all parens.
              if formattable[0] && fn == ""
                formattable.unshift(true)
                next
              end

              # This is not a known math function so don't format it
              formattable.unshift(false)
              next
            end

            # We've exited the function so format according to the parent function's
            # type.
            if char == ")"
              result << char
              formattable.shift
              next
            end

            # Add spaces after commas in math functions
            if char == "," && formattable[0]
              result << ", "
              next
            end

            # Skip over consecutive whitespace
            next if char == " " && formattable[0] && result[-1] == " "

            # Add whitespace around operators inside math functions
            if OPERATORS.include?(char) && formattable[0]
              trimmed = result.rstrip
              prev_char = trimmed[-1]
              prev_prev_char = trimmed[-2]
              next_char = scanner.peek(1)

              # Do not add spaces for scientific notation, e.g.: `-3.4e-2`
              if prev_char&.match?(/[eE]/) && prev_prev_char&.between?("0", "9")
                result << char
                next
              end

              # If we're preceded by an operator don't add spaces
              if OPERATORS.include?(prev_char)
                result << char
                next
              end

              # If we're at the beginning of an argument don't add spaces
              if prev_char&.match?(/[(,]/)
                result << char
                next
              end

              # Add spaces only after the operator if we already have spaces before it
              if input[scanner.pos - 2] == " "
                result << "#{char} "
                next
              end

              # Add spaces around the operator, if...
              if prev_char&.between?("0", "9") || # Previous is a digit
                 next_char&.between?("0", "9") || # Next is a digit
                 prev_char == ")" || # Previous is end of a function call (or parenthesized expression)
                 next_char == "(" || # Next is start of a parenthesized expression
                 OPERATORS.include?(next_char) || # Next is an operator
                 (last_value_pos && last_value_pos == scanner.pos - 1) # Previous position was a value (+ unit)
                result << " #{char} "
                next
              end

              # Everything else
              result << char
              next
            end

            # Handle all other characters
            result << char
          end

          result
        end
      end
    end
  end
end
