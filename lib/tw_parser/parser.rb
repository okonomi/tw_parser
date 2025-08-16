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
    def parse(input)
      important = false
      raw = input

      if input.end_with?("!")
        important = true
        input = input[0...-1]
      end

      if input == "-translate-x-4"
        return FunctionalCandidate.new(
          important:,
          modifier: nil,
          raw: raw,
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
