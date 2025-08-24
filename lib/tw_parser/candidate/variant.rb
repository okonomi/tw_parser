# rbs_inline: enabled
# frozen_string_literal: true

module TwParser
  module Candidate
    ArbitraryVariant = Data.define(
      :selector, #: String
      # Whether or not the selector is a relative selector
      # @see https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_selectors/Selector_structure#relative_selector
      :relative #: bool
    )

    StaticVariant = Data.define(
      :root #: String
    )

    FunctionalVariant = Data.define(
      :root, #: String
      :value, #: ArbitraryVariantValue | NamedVariantValue | nil
      :modifier #: ArbitraryModifier | NamedModifier | nil
    )

    ArbitraryVariantValue = Data.define(
      :value #: String
    )

    NamedVariantValue = Data.define(
      :value #: String
    )
  end
end
