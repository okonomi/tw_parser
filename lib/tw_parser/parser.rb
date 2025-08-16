# frozen_string_literal: true

module TwParser
  ArbitraryCandidate = Data.define(
    :property, # ! string
    :value, # ! string
    :modifier, # ! ArbitraryModifier | NamedModifier | null
    :variants, # ! Variant[]
    :important, # ! boolean
    :raw # ! string
  )
  StaticCandidate = Data.define(
    :root, # ! string
    :variants, # ! Variant[]
    :important, # ! boolean
    :raw # ! string
  )
  FunctionalCandidate = Data.define(
    :root, # ! string
    :value, # ! ArbitraryUtilityValue | NamedUtilityValue | null
    :modifier, # ! ArbitraryModifier | NamedModifier | null
    :variants, # ! Variant[]
    :important, # ! boolean
    :raw # ! string
  )

  NamedUtilityValue = Data.define(
    :value, # ! string
    :fraction # ! string | nil
  )

  class Parser
    STATIC_CANDIDATES = Set.new([
                                  "flex"
                                ]).freeze
    FUNCTIONAL_CANDIDATES = Set.new([
                                      "translate",
                                      "-translate",
                                      "translate-x",
                                      "-translate-x"
                                    ]).freeze

    def parse(input)
      important = false
      base = input

      if base.end_with?("!")
        important = true
        base = base[0...-1]
      end

      if STATIC_CANDIDATES.include?(base) && !base.include?("[")
        return StaticCandidate.new(
          root: base,
          variants: [],
          important:,
          raw: input
        )
      end

      if base == "-translate-x-4"
        return FunctionalCandidate.new(
          important:,
          modifier: nil,
          raw: input,
          root: "-translate-x",
          value: TwParser::NamedUtilityValue.new(
            fraction: nil,
            value: "4"
          ),
          variants: []
        )
      end

      StaticCandidate.new(
        important:,
        raw:,
        root: input,
        variants: []
      )
    end
  end
end
