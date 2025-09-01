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
          when " "
            # 1. Handle everything before the separator as a word
            # Handle everything before the closing paren as a word
            unless buffer.empty?
              node = ValueWordNode.new(value: buffer)
              ast << node
              buffer = +""
            end

            # 2. Look ahead and find the end of the separator
            pos = (input.index(/[^ ]/, idx + 1) || (input.length - 1)) - 1
            ast << ValueSeparatorNode.new(value: input.slice(idx..pos))
            idx = pos

          # Start of a string.
          when "'", '"'
            pos = input.index(current_char, idx + 1) || (input.length - 1)
            buffer << input.slice(idx..pos)
            idx = pos
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
