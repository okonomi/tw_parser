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
        stack = [] #: Array[ValueFunctionNode | nil]
        parent = nil #: ValueFunctionNode | nil
        buffer = +""

        idx = 0
        while idx < input.length
          current_char = input[idx]
          unless current_char.nil?
            case current_char
            when " ", ",", "/", "\n", "\t"
              # 1. Handle everything before the separator as a word
              # Handle everything before the closing paren as a word
              unless buffer.empty?
                node = ValueWordNode.new(value: buffer)
                if parent
                  parent.nodes << node
                else
                  ast << node
                end
                buffer = +""
              end

              # 2. Look ahead and find the end of the separator
              pos = (input.index(%r{[^ ,/\n\t]}, idx + 1) || (input.length - 1)) - 1
              node = ValueSeparatorNode.new(value: substring(input, idx, pos))
              if parent
                parent.nodes << node
              else
                ast << node
              end
              idx = pos

            # Start of a string.
            when "'", '"'
              pos = input.index(current_char, idx + 1) || (input.length - 1)
              buffer << substring(input, idx, pos)
              idx = pos

            # Start of a function call.
            #
            # E.g.:
            #
            # ```css
            # foo(bar, baz)
            #    ^
            # ```
            when "("
              node = ValueFunctionNode.new(value: buffer, nodes: [])
              buffer = +""

              if parent
                parent.nodes << node
              else
                ast << node
              end
              stack << node
              parent = node

            # End of a function call.
            #
            # E.g.:
            #
            # ```css
            # foo(bar, baz)
            #             ^
            # ```
            when ")"
              tail = stack.pop

              unless buffer.empty?
                node = ValueWordNode.new(value: buffer)
                tail&.nodes&.push(node)
                buffer = +""
              end

              parent = if stack.empty?
                         nil
                       else
                         stack.last
                       end
            else
              buffer << current_char
            end
          end

          idx += 1
        end

        # Collect the remainder as a word
        ast << ValueWordNode.new(value: buffer) unless buffer.empty?

        ast
      end

      #: (String input, Integer start, Integer finish) -> String
      def substring(input, start, finish)
        input.slice(start..finish) or raise ArgumentError, "Invalid substring range"
      end

      #: (Array[value_ast_node]) -> Array[Hash[Symbol, untyped]]
      def extract(ast)
        ast.map do |node|
          case node
          when TwParser::ValueParser::ValueWordNode
            {
              kind: :word,
              value: node.value
            }
          when TwParser::ValueParser::ValueFunctionNode
            {
              kind: :function,
              value: node.value,
              nodes: extract(node.nodes)
            }
          when TwParser::ValueParser::ValueSeparatorNode
            {
              kind: :separator,
              value: node.value
            }
          else
            { kind: :unknown, value: node.to_s }
          end
        end
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
