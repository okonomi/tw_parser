# rbs_inline: enabled
# frozen_string_literal: true

require_relative "segment"
require_relative "utilities"
require_relative "variants"
require_relative "candidate/modifier"
require_relative "candidate/variant"
require_relative "candidate/candidate"

module TwParser
  # @rbs!
  #
  #  type variant = TwParser::Candidate::ArbitraryVariant | TwParser::Candidate::StaticVariant | TwParser::Candidate::FunctionalVariant
  #  type candidate_modifier = TwParser::Candidate::ArbitraryModifier | TwParser::Candidate::NamedModifier
  #  type candidate_value = TwParser::Candidate::ArbitraryUtilityValue | TwParser::Candidate::NamedUtilityValue
  #  type candidate = TwParser::Candidate::ArbitraryCandidate | TwParser::Candidate::StaticCandidate | TwParser::Candidate::FunctionalCandidate

  class Parser
    STATIC_CANDIDATES = Set.new([
                                  "flex"
                                ]).freeze
    VARIANTS = Set.new([
                         "supports"
                       ]).freeze

    #: (String input, utilities: TwParser::Utilities, variants: TwParser::Variants) -> (candidate | nil)
    def parse(input, utilities:, variants:)
      # hover:focus:underline
      # ^^^^^ ^^^^^^           -> Variants
      #             ^^^^^^^^^  -> Base
      raw_variants = TwParser.segment(input, ":")

      base = raw_variants.pop

      parsed_candidate_variants = []

      raw_variants.reverse_each do |variant|
        parsed_variant = parse_variant(variant, variants:)
        return nil if parsed_variant.nil?

        parsed_candidate_variants.push(parsed_variant)
      end

      important = false

      if base.end_with?("!")
        important = true
        base = base[0...-1]
      end

      if STATIC_CANDIDATES.include?(base) && !base.include?("[")
        return TwParser::Candidate::StaticCandidate.new(
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

        return TwParser::Candidate::ArbitraryCandidate.new(
          property: property,
          value: value,
          modifier: parsed_modifier,
          variants: parsed_candidate_variants,
          important:,
          raw: input
        )
      end

      roots = find_roots(base_without_modifier) do |root|
        utilities.has(root, "functional")
      end

      return nil if roots.empty?

      roots.each do |root, value| # rubocop:disable Lint/UnreachableLoop
        candidate = TwParser::Candidate::FunctionalCandidate.new(
          root: root,
          modifier: parsed_modifier,
          value: nil,
          variants: parsed_candidate_variants,
          important:,
          raw: input
        )

        return candidate if value.nil?

        if value.start_with?("[")
          return nil unless value.end_with?("]")

          # TODO: no implemented yet
        else
          # Some utilities support fractions as values, e.g. `w-1/2`. Since it's
          # ambiguous whether the slash signals a modifier or not, we store the
          # fraction separately in case the utility matcher is interested in it.
          fraction =
            if modifier_segment.nil? || candidate.modifier.is_a?(TwParser::Candidate::ArbitraryModifier)
              nil
            else
              "#{value}/#{modifier_segment}"
            end

          candidate = candidate.with(value: TwParser::Candidate::NamedUtilityValue.new(
            value:,
            fraction:
          ))
        end

        return candidate
      end
    end

    #: (String variant, variants: TwParser::Variants) -> (variant | nil)
    def parse_variant(variant, variants:)
      # Arbitrary variants
      if variant.start_with?("[") && variant.end_with?("]")
        selector = decode_arbitrary_value(variant[1..-2])
        relative = selector.start_with?(">", "+", "~")

        return TwParser::Candidate::ArbitraryVariant.new(
          selector: selector,
          relative: relative
        )
      end

      # Functional variants
      variant_without_modifier, _modifier, _additional_modifier = TwParser.segment(variant, "/")

      roots = find_roots(variant_without_modifier) do |root|
        variants.has(root)
      end
      roots.each do |root, value|
        case variants.kind(root)
        when :static
          return TwParser::Candidate::StaticVariant.new(
            root: variant
          )
        when :functional
          if value.end_with?(")")
            # Discard values like `foo-(--bar)`
            next unless value.start_with?("(")

            arbitrary_value = decode_arbitrary_value(value[1..-2])

            return TwParser::Candidate::FunctionalVariant.new(
              root: root,
              value: TwParser::Candidate::ArbitraryVariantValue.new(
                value: "var(#{arbitrary_value})"
              ),
              modifier: nil
            )
          end
        end
      end

      nil
    end

    def decode_arbitrary_value(value)
      value.gsub("_", " ")
    end

    #: (String modifier) -> candidate_modifier
    def parse_modifier(modifier)
      if modifier.start_with?("[") && modifier.end_with?("]")
        arbitrary_value = decode_arbitrary_value(modifier[1..-2])

        return TwParser::Candidate::ArbitraryModifier.new(
          value: arbitrary_value
        )
      end

      TwParser::Candidate::NamedModifier.new(
        value: modifier
      )
    end

    #: (String input) { (String) -> bool } -> [[String, String?]]
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
