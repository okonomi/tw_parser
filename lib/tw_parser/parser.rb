# rbs_inline: enabled
# frozen_string_literal: true

require_relative "segment"

module TwParser
  ArbitraryUtilityValue = Data.define(
    # ```
    # bg-[color:var(--my-color)]
    #     ^^^^^
    #
    # bg-(color:--my-color)
    #     ^^^^^
    # ```
    :data_type, #: String | nil
    # ```
    # bg-[#0088cc]
    #     ^^^^^^^
    #
    # bg-[var(--my_variable)]
    #     ^^^^^^^^^^^^^^^^^^
    #
    # bg-(--my_variable)
    #     ^^^^^^^^^^^^^^
    # ```
    :value #: String
  ) do
    def inspect
      {
        kind: :arbitrary,
        data_type:,
        value:
      }
    end
  end

  NamedUtilityValue = Data.define(
    :value, #: String
    :fraction #: String | nil
  ) do
    def inspect
      {
        kind: :named,
        value:,
        fraction:
      }
    end
  end

  ArbitraryModifier = Data.define(
    # bg-red-500/[50%]
    #             ^^^
    :value #: String
  ) do
    def inspect
      {
        kind: :arbitrary,
        value:
      }
    end
  end

  NamedModifier = Data.define(
    # bg-red-500/50
    #            ^^
    :value #: String
  ) do
    def inspect
      {
        kind: :named,
        value:
      }
    end
  end

  # @rbs!
  #  type candidate_modifier = ArbitraryModifier | NamedModifier

  ArbitraryVariantValue = Data.define(
    :value #: String
  ) do
    def inspect
      {
        kind: :arbitrary,
        value:
      }
    end
  end

  NamedVariantValue = Data.define(
    :value #: String
  ) do
    def inspect
      {
        kind: :named,
        value:
      }
    end
  end

  ArbitraryVariant = Data.define(
    :selector, #: String
    # Whether or not the selector is a relative selector
    # @see https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_selectors/Selector_structure#relative_selector
    :relative #: bool
  ) do
    def inspect
      {
        kind: :arbitrary,
        selector:,
        relative:
      }
    end
  end

  StaticVariant = Data.define(
    :root #: String
  ) do
    def inspect
      {
        kind: :static,
        root:
      }
    end
  end

  FunctionalVariant = Data.define(
    :root, #: String
    :value, #: ArbitraryVariantValue | NamedVariantValue | nil
    :modifier #: ArbitraryModifier | NamedModifier | nil
  ) do
    def inspect
      {
        kind: :functional,
        root:,
        value: value.inspect,
        modifier:
      }
    end
  end

  # @rbs!
  #
  #  type variant = ArbitraryVariant | StaticVariant | FunctionalVariant

  ArbitraryCandidate = Data.define(
    :property, #: String
    :value, #: String
    :modifier, #: ArbitraryModifier | NamedModifier | nil
    :variants, #: Array[variant]
    :important, #: bool
    :raw #: String
  ) do
    def inspect
      {
        kind: :arbitrary,
        property:,
        value: value.inspect,
        modifier:,
        variants: variants.map(&:inspect),
        important:,
        raw:
      }
    end
  end

  StaticCandidate = Data.define(
    :root, #: String
    :variants, #: Array[variant]
    :important, #: bool
    :raw #: String
  ) do
    def inspect
      {
        kind: :static,
        root:,
        variants: variants.map(&:inspect),
        important:,
        raw:
      }
    end
  end

  FunctionalCandidate = Data.define(
    :root, #: String
    :value, #: ArbitraryUtilityValue | NamedUtilityValue | nil
    :modifier, #: ArbitraryModifier | NamedModifier | nil
    :variants, #: Array[variant]
    :important, #: bool
    :raw #: String
  ) do
    def inspect
      {
        kind: :functional,
        root:,
        value: value.inspect,
        modifier:,
        variants: variants.map(&:inspect),
        important:,
        raw:
      }
    end
  end

  # @rbs!
  #  type candidate = ArbitraryCandidate | StaticCandidate | FunctionalCandidate

  class Parser
    STATIC_CANDIDATES = Set.new([
                                  "flex"
                                ]).freeze
    FUNCTIONAL_CANDIDATES = Set.new([
                                      "translate",
                                      "-translate",
                                      "translate-x",
                                      "-translate-x",
                                      "bg"
                                    ]).freeze
    VARIANTS = Set.new([
                         "supports"
                       ]).freeze

    def parse(input)
      # hover:focus:underline
      # ^^^^^ ^^^^^^           -> Variants
      #             ^^^^^^^^^  -> Base
      raw_variants = TwParser.segment(input, ":")

      base = raw_variants.pop

      parsed_candidate_variants = []

      raw_variants.reverse_each do |variant|
        parsed_variant = parse_variant(variant)
        return nil if parsed_variant.nil?

        parsed_candidate_variants.push(parsed_variant)
      end

      important = false

      if base.end_with?("!")
        important = true
        base = base[0...-1]
      end

      if STATIC_CANDIDATES.include?(base) && !base.include?("[")
        return StaticCandidate.new(
          root: base,
          variants: parsed_candidate_variants,
          important:,
          raw: input
        )
      end

      # // Figure out the new base and the modifier segment if present.
      # //
      # // E.g.:
      # //
      # // ```
      # // bg-red-500/50
      # // ^^^^^^^^^^    -> Base without modifier
      # //            ^^ -> Modifier segment
      # // ```
      base_without_modifier, modifier_segment, _additional_modifier = TwParser.segment(base, "/")

      parsed_modifier = modifier_segment.nil? ? nil : parse_modifier(modifier_segment)

      # Arbitrary properties
      if base_without_modifier.start_with?("[")
        # Arbitrary properties should end with a `]`.
        return nil unless base_without_modifier.end_with?("]")

        base_without_modifier = base_without_modifier.delete_prefix("[").delete_suffix("]")

        idx = base_without_modifier.index(":")

        property = base_without_modifier.slice(0, idx)
        value = base_without_modifier.slice(idx + 1..)

        return TwParser::ArbitraryCandidate.new(
          property: property,
          value: value,
          modifier: parsed_modifier,
          variants: parsed_candidate_variants,
          important:,
          raw: input
        )
      end

      roots = find_roots(base_without_modifier) do |root|
        FUNCTIONAL_CANDIDATES.include?(root)
      end

      return nil if roots.empty?

      roots.each do |root, value| # rubocop:disable Lint/UnreachableLoop
        candidate = TwParser::FunctionalCandidate.new(
          root: root,
          modifier: parsed_modifier,
          value: nil,
          variants: parsed_candidate_variants,
          important:,
          raw: input
        )

        if value
          fraction = ("#{value}/#{parsed_modifier.value}" if parsed_modifier)

          candidate = candidate.with(value: TwParser::NamedUtilityValue.new(
            value:,
            fraction:
          ))
        end

        return candidate
      end
    end

    def parse_variant(variant)
      # Arbitrary variants
      if variant.start_with?("[") && variant.end_with?("]")
        selector = decode_arbitrary_value(variant[1..-2])
        relative = selector.start_with?(">", "+", "~")

        return TwParser::ArbitraryVariant.new(
          selector: selector,
          relative: relative
        )
      end

      # Functional variants
      variant_without_modifier, _modifier, _additional_modifier = TwParser.segment(variant, "/")

      roots = find_roots(variant_without_modifier) do |root|
        VARIANTS.include?(root)
      end
      roots.each do |root, value|
        if value.nil?
          return TwParser::FunctionalVariant.new(
            root: root,
            value: nil,
            modifier: nil
          )
        end

        if value.end_with?(")") # rubocop:disable Style/Next
          # Discard values like `foo-(--bar)`
          next unless value.start_with?("(")

          arbitrary_value = decode_arbitrary_value(value[1..-2])

          return TwParser::FunctionalVariant.new(
            root: root,
            value: TwParser::ArbitraryVariantValue.new(
              value: "var(#{arbitrary_value})"
            ),
            modifier: nil
          )
        end
      end

      TwParser::StaticVariant.new(
        root: variant
      )
    end

    def decode_arbitrary_value(value)
      value.gsub("_", " ")
    end

    def parse_modifier(modifier)
      TwParser::NamedModifier.new(
        value: modifier
      )
    end

    def find_roots(input, &exists)
      return [[input, nil]] if exists.call(input)

      idx = input.rindex("-", -1)
      while idx
        maybe_root = input.slice(0, idx)

        return [[maybe_root, input.slice((idx + 1)..)]] if exists.call(maybe_root)

        idx = input.rindex("-", idx - 1)
      end

      []
    end
  end
end
