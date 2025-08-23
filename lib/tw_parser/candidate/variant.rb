# rbs_inline: enabled
# frozen_string_literal: true

require_relative "modifier"

module TwParser
  module Candidate
    ArbitraryVariant = Data.define(
      :selector, #: String
      # Whether or not the selector is a relative selector
      # @see https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_selectors/Selector_structure#relative_selector
      :relative #: bool
    ) do
      # steep:ignore:start
      def inspect
        {
          kind: :arbitrary,
          selector:,
          relative:
        }
      end
      # steep:ignore:end
    end

    StaticVariant = Data.define(
      :root #: String
    ) do
      # steep:ignore:start
      def inspect
        {
          kind: :static,
          root:
        }
      end
      # steep:ignore:end
    end

    FunctionalVariant = Data.define(
      :root, #: String
      :value, #: TwParser::Candidate::ArbitraryVariantValue | TwParser::Candidate::NamedVariantValue | nil
      :modifier #: TwParser::Candidate::ArbitraryModifier | TwParser::Candidate::NamedModifier | nil
    ) do
      # steep:ignore:start
      def inspect
        {
          kind: :functional,
          root:,
          value: value&.inspect,
          modifier: modifier&.inspect
        }
      end
      # steep:ignore:end
    end

    ArbitraryVariantValue = Data.define(
      :value #: String
    ) do
      # steep:ignore:start
      def inspect
        {
          kind: :arbitrary,
          value:
        }
      end
      # steep:ignore:end
    end

    NamedVariantValue = Data.define(
      :value #: String
    ) do
      # steep:ignore:start
      def inspect
        {
          kind: :named,
          value:
        }
      end
      # steep:ignore:end
    end
  end
end
