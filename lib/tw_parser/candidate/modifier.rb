# rbs_inline: enabled
# frozen_string_literal: true

module TwParser
  module Candidate
    ArbitraryModifier = Data.define(
      # bg-red-500/[50%]
      #             ^^^
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

    NamedModifier = Data.define(
      # bg-red-500/50
      #            ^^
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
