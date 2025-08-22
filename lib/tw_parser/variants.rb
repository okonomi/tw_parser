# frozen_string_literal: true

module TwParser
  class Variants
    def initialize
      @variants = {}
    end

    def static(name, &block)
      # TODO: implement static variant registration
    end

    def functional(name, &block)
      @variants[name] = block
    end

    def compound(name, compound_type, &block)
      # TODO: implement compound variant registration
    end

    #: (String name) -> bool
    def has(name)
      @variants.key?(name)
    end
  end
end
