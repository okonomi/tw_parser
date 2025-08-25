# rbs_inline: enabled
# frozen_string_literal: true

module TwParser
  class Variants
    def initialize
      @variants = {}
    end

    def static(name, &block)
      @variants[name] = { kind: :static, block: }
    end

    def functional(name, &block)
      @variants[name] = { kind: :functional, block: }
    end

    def compound(name, compound_type, &block)
      # TODO: implement compound variant registration
    end

    #: (String name) -> bool
    def has(name)
      @variants.key?(name)
    end

    #: (String name) -> (Symbol | nil)
    def kind(name)
      @variants[name]&.dig(:kind)
    end
  end
end
