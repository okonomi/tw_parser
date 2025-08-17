# frozen_string_literal: true

module TwParser
  module_function

  def segment(input, delimiter)
    segments = input.split(delimiter)
    base = segments.pop
    segments.reverse.push(base)
  end
end
