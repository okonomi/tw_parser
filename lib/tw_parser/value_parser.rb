# rbs_inline: enabled
# frozen_string_literal: true

module TwParser
  class ValueParser
    class << self
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
