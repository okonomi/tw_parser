# frozen_string_literal: true

module TwParser
  module_function

  def segment(input, delimiter)
    closing_bracket_stack = []

    parts = []
    last_pos = 0
    len = input.length

    idx = 0
    while idx < len
      char = input[idx]

      if closing_bracket_stack.empty? && char == delimiter
        parts << input[last_pos...idx]
        last_pos = idx + 1
        idx += 1
        next
      end

      case char
      when '"', "'"
        while (idx += 1) < len
          next_char = input[idx]

          if next_char == "\\"
            idx += 1
            next
          end

          break if next_char == char
        end
      when "("
        closing_bracket_stack.push(")")
      when "["
        closing_bracket_stack.push("]")
      when "{"
        closing_bracket_stack.push("}")
      when ")", "]", "}"
        closing_bracket_stack.pop if closing_bracket_stack.last == char
      end

      idx += 1
    end

    parts << input[last_pos..]

    parts
  end
end
