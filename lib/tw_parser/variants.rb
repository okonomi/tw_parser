# rbs_inline: enabled
# frozen_string_literal: true

module TwParser
  class Variants
    # @rbs!
    #
    #   type compounds = 0 | 1 | 2

    COMPOUND_NEVER = 0 #: 0
    COMPOUND_AT_RULES = 1 << 0 #: 1
    COMPOUND_STYLE_RULES = 1 << 1 #: 2

    def initialize
      @variants = {}
    end

    def static(name, &block)
      @variants[name] = { kind: :static, block: }
    end

    def functional(name, &block)
      @variants[name] = { kind: :functional, block: }
    end

    #: (::String name, compounds compounds_with) { (untyped) -> untyped } -> void
    def compound(name, compounds_with, &block)
      # TODO: implement compound variant registration
    end

    #: (String name) -> bool
    def has?(name)
      @variants.key?(name)
    end

    #: (String name) -> (Symbol | nil)
    def kind(name)
      @variants[name]&.dig(:kind)
    end
  end
end
