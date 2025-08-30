# rbs_inline: enabled
# frozen_string_literal: true

require_relative "util"

module TwParser
  module Candidate
    ArbitraryCandidate = Data.define(
      :property, #: String
      :value, #: String
      :modifier, #: ArbitraryModifier | NamedModifier | nil
      :variants, #: Array[variant]
      :important, #: bool
      :raw #: String
    ) do
      def inspect
        Util.extract_candidate_info(self).to_s
      end
    end

    StaticCandidate = Data.define(
      :root, #: String
      :variants, #: Array[variant]
      :important, #: bool
      :raw #: String
    ) do
      def inspect
        Util.extract_candidate_info(self).to_s
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
        Util.extract_candidate_info(self).to_s
      end
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
    )

    NamedUtilityValue = Data.define(
      :value, #: String
      :fraction #: String | nil
    )
  end
end
