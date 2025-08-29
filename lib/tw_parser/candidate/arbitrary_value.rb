# rbs_inline: enabled
# frozen_string_literal: true

module TwParser
  module Candidate
    class ArbitraryValue
      class << self
        #: (String input) -> String
        def decode(input)
          # There are definitely no functions in the input, so bail early
          return input.tr("_", " ") unless input.include?("(")

          # TODO: implement ValueParser
          input.gsub(/\(.+?\)/) do |match|
            match.split(",").map.with_index do |v, i|
              i.zero? ? v : v.tr("_", " ")
            end.join(",")
          end
        end
      end
    end
  end
end
