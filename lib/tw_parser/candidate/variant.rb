# rbs_inline: enabled
# frozen_string_literal: true

module TwParser
  module Candidate
    # @rbs!
    #
    #   type variant = ArbitraryVariant | StaticVariant | FunctionalVariant | CompoundVariant

    # Arbitrary variants are variants that take a selector and generate a variant
    # on the fly.
    #
    # E.g.: `[&_p]`
    ArbitraryVariant = Data.define(
      :selector, #: String
      # Whether or not the selector is a relative selector
      # @see https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_selectors/Selector_structure#relative_selector
      :relative #: bool
    )

    # Static variants are variants that don't take any arguments.
    #
    # E.g.: `hover`
    StaticVariant = Data.define(
      :root #: String
    )

    # Functional variants are variants that can take an argument. The argument is
    # either a named variant value or an arbitrary variant value.
    #
    # E.g.:
    #
    # - `aria-disabled`
    # - `aria-[disabled]`
    # - `@container-size`          -> @container, with named value `size`
    # - `@container-[inline-size]` -> @container, with arbitrary variant value `inline-size`
    # - `@container`               -> @container, with no value
    FunctionalVariant = Data.define(
      :root, #: String
      :value, #: ArbitraryVariantValue | NamedVariantValue | nil
      :modifier #: ArbitraryModifier | NamedModifier | nil
    )

    # Compound variants are variants that take another variant as an argument.
    #
    # E.g.:
    #
    # - `has-[&_p]`
    # - `group-*`
    # - `peer-*`
    CompoundVariant = Data.define(
      :root, #: String
      :modifier, #: ArbitraryModifier | NamedModifier | nil
      :variant #: variant
    )

    ArbitraryVariantValue = Data.define(
      :value #: String
    )

    NamedVariantValue = Data.define(
      :value #: String
    )
  end
end
