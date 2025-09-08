# rbs_inline: enabled
# frozen_string_literal: true

require_relative "../utils/segment"
require_relative "../utilities"
require_relative "../variants"
require_relative "modifier"
require_relative "variant"
require_relative "candidate"
require_relative "../utils/arbitrary_value"

module TwParser
  module Candidate
    class Parser
      # @rbs!
      #
      #  type candidate = ArbitraryCandidate | StaticCandidate | FunctionalCandidate

      #: (String input, utilities: TwParser::Utilities, variants: TwParser::Variants, ?prefix: String?) -> (candidate | nil)
      def parse(input, utilities:, variants:, prefix: nil)
        # hover:focus:underline
        # ^^^^^ ^^^^^^           -> Variants
        #             ^^^^^^^^^  -> Base
        raw_variants = Utils::Segment.parse(input, ":")

        # A prefix is a special variant used to prefix all utilities. When present,
        # all utilities must start with that variant which we will then remove from
        # the variant list so no other part of the codebase has to know about it.
        if prefix
          return nil if raw_variants.length == 1
          return nil if raw_variants[0] != prefix

          raw_variants.shift
        end

        base = raw_variants.pop #: ::String

        parsed_candidate_variants = [] #: Array[variant]

        raw_variants.reverse_each do |variant|
          parsed_variant = parse_variant(variant, variants:)
          return nil if parsed_variant.nil?

          parsed_candidate_variants.push(parsed_variant)
        end

        important = false

        if base.end_with?("!")
          important = true
          base = base.delete_suffix("!")
        end

        # Check for an exact match of a static utility first as long as it does not
        # look like an arbitrary value.
        if utilities.has?(base, "static") && !base.include?("[")
          return StaticCandidate.new(
            root: base,
            variants: parsed_candidate_variants,
            important:,
            raw: input
          )
        end

        # Figure out the new base and the modifier segment if present.
        #
        # E.g.:
        #
        # ```
        # bg-red-500/50
        # ^^^^^^^^^^    -> Base without modifier
        #            ^^ -> Modifier segment
        # ```
        base_without_modifier, modifier_segment, additional_modifier = Utils::Segment.parse(base, "/")
        return nil if base_without_modifier.nil?

        # If there's more than one modifier, the utility is invalid.
        #
        # E.g.:
        #
        # - `bg-red-500/50/50`
        return nil unless additional_modifier.nil?

        parsed_modifier = modifier_segment.nil? ? nil : parse_modifier(modifier_segment)

        # Empty arbitrary values are invalid. E.g.: `[color:red]/[]` or `[color:red]/()`.
        #                                                        ^^                  ^^
        #                                           `bg-[#0088cc]/[]` or `bg-[#0088cc]/()`.
        #                                                         ^^                   ^^
        return nil if !modifier_segment.nil? && parsed_modifier.nil?

        # Arbitrary properties
        if base_without_modifier.start_with?("[")
          # Arbitrary properties should end with a `]`.
          return nil unless base_without_modifier.end_with?("]")

          # The property part of the arbitrary property can only start with a-z
          # lowercase or a dash `-` in case of vendor prefixes such as `-webkit-`
          # or `-moz-`.
          #
          # Otherwise, it is an invalid candidate, and skip continue parsing.
          char_code = base_without_modifier[1]
          return nil unless char_code == "-" || char_code&.between?("a", "z")

          base_without_modifier = base_without_modifier.delete_prefix("[").delete_suffix("]")

          # Arbitrary properties consist of a property and a value separated by a
          # `:`. If the `:` cannot be found, then it is an invalid candidate, and we
          # can skip continue parsing.
          #
          # Since the property and the value should be separated by a `:`, we can
          # also verify that the colon is not the first or last character in the
          # candidate, because that would make it invalid as well.
          idx = base_without_modifier.index(":")
          return nil if idx.nil? || [0, base_without_modifier.length - 1].include?(idx)

          property = base_without_modifier.slice(0, idx) #: String
          value = base_without_modifier.slice((idx + 1)..) #: String

          # Values can't contain `;` or `}` characters at the top-level.
          return nil unless Utils::ArbitraryValue.valid?(value)

          return ArbitraryCandidate.new(
            property: property,
            value: value,
            modifier: parsed_modifier,
            variants: parsed_candidate_variants,
            important:,
            raw: input
          )
        end

        # The different "versions"" of a candidate that are utilities
        # e.g. `['bg', 'red-500']` and `['bg-red', '500']`
        # let roots: Iterable<Root>
        roots = [] #: Array[root]

        # If the base of the utility ends with a `]`, then we know it's an arbitrary
        # value. This also means that everything before the `[…]` part should be the
        # root of the utility.
        #
        # E.g.:
        #
        # ```
        # bg-[#0088cc]
        # ^^           -> Root
        #    ^^^^^^^^^ -> Arbitrary value
        #
        # border-l-[#0088cc]
        # ^^^^^^^^           -> Root
        #          ^^^^^^^^^ -> Arbitrary value
        # ```
        if base_without_modifier.end_with?("]")
          idx = base_without_modifier.index("-[")
          return nil if idx.nil?

          root = base_without_modifier.slice(0, idx) #: String

          # The root of the utility should exist as-is in the utilities map. If not,
          # it's an invalid utility and we can skip continue parsing.
          return nil unless utilities.has?(root, "functional")

          value = base_without_modifier.slice((idx + 1)..)

          roots = [[root, value]] #: Array[root]
        # If the base of the utility ends with a `)`, then we know it's an arbitrary
        # value that encapsulates a CSS variable. This also means that everything
        # before the `(…)` part should be the root of the utility.
        #
        # E.g.:
        #
        # bg-(--my-var)
        # ^^            -> Root
        #    ^^^^^^^^^^ -> Arbitrary value
        # ```
        elsif base_without_modifier.end_with?(")")
          idx = base_without_modifier.index("-(")
          return nil if idx.nil?

          root = base_without_modifier.slice(0, idx) #: String

          # The root of the utility should exist as-is in the utilities map. If not,
          # it's an invalid utility and we can skip continue parsing.
          return nil unless utilities.has?(root, "functional")

          value = base_without_modifier.slice((idx + 2)..-2) #: String

          parts = Utils::Segment.parse(value, ":")
          data_type = nil
          if parts.length == 2
            data_type = parts[0]
            value = parts[1]
          end

          # An arbitrary value with `(…)` should always start with `--` since it
          # represents a CSS variable.
          return nil unless value&.start_with?("--")

          # Values can't contain `;` or `}` characters at the top-level.
          return nil unless Utils::ArbitraryValue.valid?(value)

          roots = [[root, data_type.nil? ? "[var(#{value})]" : "[#{data_type}:var(#{value})]"]] #: Array[root]
        else
          roots = find_roots(base_without_modifier) do |root|
            utilities.has?(root, "functional")
          end
        end

        roots.each do |root, value|
          candidate = FunctionalCandidate.new(
            root: root,
            modifier: parsed_modifier,
            value: nil,
            variants: parsed_candidate_variants,
            important:,
            raw: input
          )

          return candidate if value.nil?

          start_arbitrary_idx = value.index("[")
          if !start_arbitrary_idx.nil?
            # Arbitrary values must end with a `]`.
            return nil unless value.end_with?("]")

            arbitrary_value = Utils::ArbitraryValue.decode(
              value.slice((start_arbitrary_idx + 1)..-2) #: String
            )

            # Values can't contain `;` or `}` characters at the top-level.
            next unless Utils::ArbitraryValue.valid?(arbitrary_value)

            typehint, arbitrary_value = arbitrary_value.split(":") if arbitrary_value.include?(":")
            return nil if arbitrary_value.nil?

            # Empty arbitrary values are invalid. E.g.: `p-[]`
            #                                              ^^
            next if arbitrary_value.strip.empty?

            candidate = candidate.with(value: ArbitraryUtilityValue.new(
              data_type: typehint,
              value: arbitrary_value
            ))
          else
            # Some utilities support fractions as values, e.g. `w-1/2`. Since it's
            # ambiguous whether the slash signals a modifier or not, we store the
            # fraction separately in case the utility matcher is interested in it.
            fraction =
              if modifier_segment.nil? || candidate.modifier.is_a?(ArbitraryModifier)
                nil
              else
                "#{value}/#{modifier_segment}"
              end

            candidate = candidate.with(value: NamedUtilityValue.new(
              value:,
              fraction:
            ))
          end

          return candidate
        end

        nil
      end

      #: (String variant, variants: TwParser::Variants) -> (variant | nil)
      def parse_variant(variant, variants:)
        # Arbitrary variants
        if variant.start_with?("[") && variant.end_with?("]")
          # TODO: Breaking change
          #
          # @deprecated Arbitrary variants containing at-rules with other selectors
          # are deprecated. Use stacked variants instead.
          #
          # Before:
          #  - `[@media(width>=123px){&:hover}]:`
          #
          # After:
          #  - `[@media(width>=123px)]:[&:hover]:`
          #  - `[@media(width>=123px)]:hover:`
          return nil if variant[1] == "@" && variant.include?("&")

          selector = Utils::ArbitraryValue.decode(
            variant.slice(1..-2) #: String
          )

          # Values can't contain `;` or `}` characters at the top-level.
          return nil unless Utils::ArbitraryValue.valid?(selector)

          relative = selector.start_with?(">", "+", "~")

          return ArbitraryVariant.new(
            selector: selector,
            relative: relative
          )
        end

        # Functional and compound variants

        # group-hover/group-name
        # ^^^^^^^^^^^            -> Variant without modifier
        #             ^^^^^^^^^^ -> Modifier
        variant_without_modifier, modifier, additional_modifier = Utils::Segment.parse(variant, "/")
        return nil if variant_without_modifier.nil?

        # If there's more than one modifier, the variant is invalid.
        #
        # E.g.:
        #
        # - `group-hover/foo/bar`
        return nil unless additional_modifier.nil?

        roots = find_roots(variant_without_modifier) do |root|
          variants.has?(root)
        end

        roots.each do |root, value|
          case variants.kind(root)
          when :static
            return StaticVariant.new(
              root: variant
            )

          when :functional
            parsed_modifier = modifier.nil? ? nil : parse_modifier(modifier)
            # Empty arbitrary values are invalid. E.g.: `@max-md/[]:` or `@max-md/():`
            #                                                    ^^               ^^
            return nil if !modifier.nil? && parsed_modifier.nil?

            if value.nil?
              return FunctionalVariant.new(
                root: root,
                modifier: parsed_modifier,
                value: nil
              )
            end

            if value.end_with?("]")
              # Discard values like `foo-[#bar]`
              next unless value.start_with?("[")

              arbitrary_value = Utils::ArbitraryValue.decode(
                value.slice(1..-2) #: String
              )

              # Values can't contain `;` or `}` characters at the top-level.
              return nil unless Utils::ArbitraryValue.valid?(arbitrary_value)

              # Empty arbitrary values are invalid. E.g.: `data-[]:`
              #                                                 ^^
              return nil if arbitrary_value.strip.empty?

              return FunctionalVariant.new(
                root: root,
                value: ArbitraryVariantValue.new(
                  value: arbitrary_value
                ),
                modifier: parsed_modifier
              )
            end

            if value.end_with?(")")
              # Discard values like `foo-(--bar)`
              next unless value.start_with?("(")

              arbitrary_value = Utils::ArbitraryValue.decode(
                value.slice(1..-2) #: String
              )

              # Arbitrary values must start with `--` since it represents a CSS variable.
              return nil unless arbitrary_value.start_with?("--")

              return FunctionalVariant.new(
                root: root,
                value: ArbitraryVariantValue.new(
                  value: "var(#{arbitrary_value})"
                ),
                modifier: nil
              )
            end

            return FunctionalVariant.new(
              root: root,
              value: NamedVariantValue.new(
                value: value
              ),
              modifier: parsed_modifier
            )

          when :compound
            return nil if value.nil?

            sub_variant = parse_variant(value, variants: variants)
            return nil if sub_variant.nil?

            parsed_modifier = modifier.nil? ? nil : parse_modifier(modifier)
            # Empty arbitrary values are invalid. E.g.: `group-focus/[]:` or `group-focus/():`
            #                                                        ^^                   ^^
            # if (modifier !== null && parsedModifier === null) return null
            return nil if !modifier.nil? && parsed_modifier.nil?

            return CompoundVariant.new(
              root:,
              modifier: parsed_modifier,
              variant: sub_variant
            )
          end
        end

        nil
      end

      #: (String modifier) -> (ArbitraryModifier | NamedModifier | nil)
      def parse_modifier(modifier)
        if modifier.start_with?("[") && modifier.end_with?("]")
          arbitrary_value = Utils::ArbitraryValue.decode(
            modifier.slice(1..-2) #: String
          )

          # Values can't contain `;` or `}` characters at the top-level.
          return nil unless Utils::ArbitraryValue.valid?(arbitrary_value)

          # Empty arbitrary values are invalid. E.g.: `data-[]:`
          #                                                 ^^
          return nil if arbitrary_value.strip.empty?

          return ArbitraryModifier.new(
            value: arbitrary_value
          )
        end

        if modifier.start_with?("(") && modifier.end_with?(")")
          # Drop the `(` and `)` characters
          modifier = modifier.slice(1..-2) #: String

          # A modifier with `(…)` should always start with `--` since it
          # represents a CSS variable.
          return nil unless modifier.start_with?("--")

          # Values can't contain `;` or `}` characters at the top-level.
          return nil unless Utils::ArbitraryValue.valid?(modifier)

          # Wrap the value in `var(…)` to ensure that it is a valid CSS variable.
          modifier = "var(#{modifier})"

          arbitrary_value = Utils::ArbitraryValue.decode(modifier)

          return ArbitraryModifier.new(
            value: arbitrary_value
          )
        end

        NamedModifier.new(
          value: modifier
        )
      end

      # @rbs!
      #
      #   type root = [
      #     # The root of the utility, e.g.: `bg-red-500`
      #     #                                 ^^
      #     ::String,
      #
      #     # The value of the utility, e.g.: `bg-red-500`
      #     #                                     ^^^^^^^
      #     ::String | nil
      #   ]

      #: (String input) { (String) -> bool } -> Array[root]
      def find_roots(input)
        # If there is an exact match, then that's the root.
        return [[input, nil]] if yield(input)

        # Otherwise test every permutation of the input by iteratively removing
        # everything after the last dash.
        idx = input.rindex("-", -1)

        # Determine the root and value by testing permutations of the incoming input.
        #
        # In case of a candidate like `bg-red-500`, this looks like:
        #
        # `bg-red-500` -> No match
        # `bg-red`     -> No match
        # `bg`         -> Match
        while idx
          maybe_root = input.slice(0, idx)

          if maybe_root && yield(maybe_root)
            root_value = input.slice((idx + 1)..)

            # If the leftover value is an empty string, it means that the value is an
            # invalid named value, e.g.: `bg-`. This makes the candidate invalid and we
            # can skip any further parsing.
            break if root_value == ""

            return [[maybe_root, root_value]]
          end

          idx = input.rindex("-", idx - 1)
        end

        # Try '@' variant after permutations. This allows things like `@max` of `@max-foo-bar`
        # to match before looking for `@`.
        return [["@", input.slice(1..)]] if input[0] == "@" && yield("@")

        []
      end
    end
  end
end
