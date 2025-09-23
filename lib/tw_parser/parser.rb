# rbs_inline: enabled
# frozen_string_literal: true

# Wrapper for TwParser::Candidate::Parser
module TwParser
  class Parser
    # @rbs!
    #
    #   @parser: TwParser::Candidate::Parser
    #   @design_system: TwParser::DesignSystem

    def initialize
      @parser = TwParser::Candidate::Parser.new
      @design_system = DesignSystem.build
    end

    #: (::String input) -> (TwParser::Candidate::Parser::candidate | nil)
    def parse(input)
      @parser.parse(input, @design_system)
    end
  end
end
