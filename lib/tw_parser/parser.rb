# rbs_inline: enabled
# frozen_string_literal: true

# Wrapper for TwParser::Candidate::Parser
module TwParser
  class Parser
    def initialize
      @parser = TwParser::Candidate::Parser.new
      @utilities = TwParser::Utilities.new.tap do |u|
        u.static("flex") { [] }
        u.functional("translate-x") { [] }
        u.functional("-translate-x") { [] }
        u.functional("bg") { [] }
      end
      @variants = TwParser::Variants.new.tap do |v|
        v.functional("supports") {}
        v.functional("data") {}
        v.static("hover") {}
        v.static("focus") {}
      end
    end

    def parse(input)
      @parser.parse(input, utilities: @utilities, variants: @variants)
    end
  end
end
