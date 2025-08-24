# rbs_inline: enabled
# frozen_string_literal: true

module TwParser
  module Candidate
    ArbitraryModifier = Data.define(
      # bg-red-500/[50%]
      #             ^^^
      :value #: String
    )

    NamedModifier = Data.define(
      # bg-red-500/50
      #            ^^
      :value #: String
    )
  end
end
