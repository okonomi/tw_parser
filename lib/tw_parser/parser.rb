# rbs_inline: enabled
# frozen_string_literal: true

# Wrapper for TwParser::Candidate::Parser
module TwParser
  class Parser
    # @rbs!
    #
    #   @parser: TwParser::Candidate::Parser
    #   @utilities: TwParser::Utilities
    #   @variants: TwParser::Variants

    def initialize
      @parser = TwParser::Candidate::Parser.new
      @utilities = TwParser::Utilities.create
      @variants = TwParser::Variants.create
    end

    #: (::String input) -> (TwParser::Candidate::Parser::candidate | nil)
    def parse(input)
      @parser.parse(input, utilities: @utilities, variants: @variants)
    end
  end
end
