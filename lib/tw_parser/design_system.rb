# rbs_inline: enabled
# frozen_string_literal: true

require_relative "utilities"
require_relative "variants"
require_relative "candidate/parser"

module TwParser
  class DesignSystem
    attr_reader :utilities #: TwParser::Utilities
    attr_reader :variants  #: TwParser::Variants
    attr_reader :parser    #: TwParser::Candidate::Parser

    #: (Utilities utilities, Variants variants) -> void
    def initialize(utilities, variants)
      @utilities = utilities
      @variants = variants
      @parser = TwParser::Candidate::Parser.new
    end

    #: (String candidate) -> (TwParser::Candidate::Parser::candidate | nil)
    def parse_candidate(candidate)
      parser.parse(candidate, self)
    end

    class << self
      #: () -> DesignSystem
      def build
        utilities = Utilities.create
        variants = Variants.create

        new(utilities, variants)
      end
    end
  end
end
