# rbs_inline: enabled
# frozen_string_literal: true

module TwParser
  class ValueParser
    ValueWordNode = Data.define(
      :value #: String
    )

    ValueFunctionNode = Data.define(
      :value, #: String
      :nodes #: Array[value_ast_node]
    )

    ValueSeparatorNode = Data.define(
      :value #: String
    )

    # @rbs!
    #
    #  type value_ast_node = ValueWordNode | ValueFunctionNode | ValueSeparatorNode
    #  type value_parent_node = ValueFunctionNode | nil

    class << self
      #: (String input) -> Array[value_ast_node]
      def parse_new(input)
        ast = [] #: Array[value_ast_node]
        buffer = +""

        idx = 0
        while idx < input.length
          current_char = input[idx]

          case current_char
          # Start of a string.
          when "'", '"'
            start = idx

            j = idx + 1
            while j < input.length
              peek_char = input[j]

              if peek_char == current_char
                idx = j
                break
              end

              j += 1
            end

            buffer << input.slice(start..j)
          else
            buffer << current_char
          end

          idx += 1
        end

        # Collect the remainder as a word
        ast << ValueWordNode.new(value: buffer) unless buffer.empty?

        ast
      end

      #: (String input) -> String
      def parse(input)
        input.gsub(/\(.+?\)/) do |match|
          match.split(",").map.with_index do |v, i|
            i.zero? ? v : convert_underscores_to_whitespace(v)
          end.join(",")
        end
      end

      # copy from TwParser::Candidate::ArbitraryValue
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
    end
  end
end
