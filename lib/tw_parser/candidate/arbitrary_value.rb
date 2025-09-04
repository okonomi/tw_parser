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

          ast = ValueParser.parse(input)
          recursively_decode_arbitrary_values(ast)
          ValueParser.to_css(ast)

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

        #: (Array[ValueParser::value_ast_node]) -> void
        def recursively_decode_arbitrary_values(ast)
          ast.each_index do |i|
            node = ast[i]
            case node
            when ValueParser::ValueFunctionNode
              ast[i] = node.with(value: convert_underscores_to_whitespace(node.value))

              if node.value == "var"
                node.nodes.each_index do |j|
                  # Don't decode underscores to spaces in the first argument of var()
                  if j.zero? && node.nodes[j].is_a?(ValueParser::ValueWordNode)
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

            when ValueParser::ValueWordNode, ValueParser::ValueSeparatorNode
              ast[i] = node.with(value: convert_underscores_to_whitespace(node.value))
            else
              raise "Unknown node type: #{node.class} #{node}"
            end
          end

          nil
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
