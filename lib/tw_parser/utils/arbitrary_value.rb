# rbs_inline: enabled
# frozen_string_literal: true

require_relative "../utils/value_parser"

module TwParser
  module Utils
    class ArbitraryValue
      class << self
        #: (String input) -> String
        def decode(input)
          # There are definitely no functions in the input, so bail early
          return convert_underscores_to_whitespace(input) unless input.include?("(")

          ast = Utils::ValueParser.parse(input)
          recursively_decode_arbitrary_values(ast)
          Utils::ValueParser.to_css(ast)

          # input = addWhitespaceAroundMathOperators(input)
        end

        # Convert `_` to ` `, except for escaped underscores `\_` they should be
        # converted to `_` instead.
        #: (String input, ?skip_underscore_to_space: bool) -> String
        def convert_underscores_to_whitespace(input, skip_underscore_to_space: false)
          escaping = false
          output = +""
          input.each_char do |char|
            output << if char == "_"
                        if skip_underscore_to_space
                          "_"
                        elsif escaping
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

        #: (Array[Utils::ValueParser::value_ast_node]) -> void
        def recursively_decode_arbitrary_values(ast)
          ast.each_index do |i|
            node = ast[i]
            case node
            when Utils::ValueParser::ValueFunctionNode
              ast[i] = node.with(value: convert_underscores_to_whitespace(node.value))

              if node.value == "var" || node.value.end_with?("_var") || node.value == "theme" || node.value.end_with?("_theme")
                node.nodes.each_index do |j|
                  # Don't decode underscores to spaces in the first argument of var()
                  if j.zero? && node.nodes[j].is_a?(Utils::ValueParser::ValueWordNode)
                    node.nodes[j] = node.nodes[j].with(value: convert_underscores_to_whitespace(node.nodes[j].value, skip_underscore_to_space: true))
                  else
                    nodes = [node.nodes[j]]
                    recursively_decode_arbitrary_values(nodes)
                    node.nodes[j] = nodes[0]
                  end
                end

                next
              end

              recursively_decode_arbitrary_values(node.nodes)

            when Utils::ValueParser::ValueWordNode, Utils::ValueParser::ValueSeparatorNode
              ast[i] = node.with(value: convert_underscores_to_whitespace(node.value))
            else
              raise "Unknown node type: #{node.class} #{node}"
            end
          end

          nil
        end

        # Determine if a given string might be a valid arbitrary value.
        #
        # Unbalanced parens, brackets, and braces are not allowed. Additionally, a
        # top-level `;` is not allowed.
        #
        # This function is very similar to `TwParser::Segment.parse` but `TwParser::Segment.parse` cannot be used
        # because we'd need to split on a bracket stack character.
        #: (String input) -> bool
        def valid?(input)
          closing_bracket_stack = [] #: Array[String]
          idx = 0
          len = input.length
          while idx < len
            char = input[idx]
            case char
            when "\\"
              # TODO
            when '"', "'"
              # TODO
            when "(", "["
              # TODO
            when "{"
              # NOTE: We intentionally do not consider `{` to move the stack pointer
              # because a candidate like `[&{color:red}]:flex` should not be valid.
            when ")", "]", "}"
              return false if closing_bracket_stack.empty?

            when ";" # rubocop:disable Lint/DuplicateBranch
              return false if closing_bracket_stack.empty?
            end

            idx += 1
          end

          true
        end
      end
    end
  end
end
