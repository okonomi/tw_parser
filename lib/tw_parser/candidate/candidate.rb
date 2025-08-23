# frozen_string_literal: true

require_relative "../parser"

module TwParser
  module Candidate
    # @rbs!
    #
    #  type variant = TwParser::Candidate::ArbitraryVariant | TwParser::Candidate::StaticVariant | TwParser::Candidate::FunctionalVariant
    #  type candidate_modifier = TwParser::Candidate::ArbitraryModifier | TwParser::Candidate::NamedModifier
    #  type candidate_value = TwParser::Candidate::ArbitraryUtilityValue | TwParser::Candidate::NamedUtilityValue

    ArbitraryCandidate = Data.define(
      :property, #: String
      :value, #: String
      :modifier, #: candidate_modifier | nil
      :variants, #: Array[variant]
      :important, #: bool
      :raw #: String
    ) do
      # steep:ignore:start
      def inspect
        {
          kind: :arbitrary,
          property:,
          value:,
          modifier: modifier&.inspect,
          variants: variants.map(&:inspect),
          important:,
          raw:
        }
      end
      # steep:ignore:end
    end

    StaticCandidate = Data.define(
      :root, #: String
      :variants, #: Array[variant]
      :important, #: bool
      :raw #: String
    ) do
      # steep:ignore:start
      def inspect
        {
          kind: :static,
          root:,
          variants: variants.map(&:inspect),
          important:,
          raw:
        }
      end
      # steep:ignore:end
    end

    FunctionalCandidate = Data.define(
      :root, #: String
      :value, #: candidate_value | nil
      :modifier, #: candidate_modifier | nil
      :variants, #: Array[variant]
      :important, #: bool
      :raw #: String
    ) do
      # steep:ignore:start
      def inspect
        {
          kind: :functional,
          root:,
          value: value&.inspect,
          modifier: modifier&.inspect,
          variants: variants.map(&:inspect),
          important:,
          raw:
        }
      end
      # steep:ignore:end
    end

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
      # steep:ignore:start
      def inspect
        {
          kind: :arbitrary,
          data_type:,
          value:
        }
      end
      # steep:ignore:end
    end

    NamedUtilityValue = Data.define(
      :value, #: String
      :fraction #: String | nil
    ) do
      # steep:ignore:start
      def inspect
        {
          kind: :named,
          value:,
          fraction:
        }
      end
      # steep:ignore:end
    end
  end
end
