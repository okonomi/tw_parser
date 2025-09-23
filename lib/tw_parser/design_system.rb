# rbs_inline: enabled
# frozen_string_literal: true

module TwParser
  class DesignSystem
    attr_reader :utilities #: TwParser::Utilities
    attr_reader :variants  #: TwParser::Variants

    #: (Utilities utilities, Variants variants) -> void
    def initialize(utilities, variants)
      @utilities = utilities
      @variants = variants
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
