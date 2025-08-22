# frozen_string_literal: true

module TwParser
  class Utilities
    def initialize
      @utilities = {}
    end

    def static(name, &block)
      # TODO: implement static utility registration
    end

    def functional(name, &block)
      @utilities[name] ||= []
      @utilities[name].push({ kind: "functional", compileFn: block })
    end

    #: (String name, String kind) -> bool
    def has(name, kind)
      @utilities.key?(name) && @utilities.fetch(name).any? { _1[:kind] == kind }
    end
  end
end
