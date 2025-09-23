# rbs_inline: enabled
# frozen_string_literal: true

require_relative "../design_system"

module TwParser
  module Compile
    class Compiler
      #: (Array[String] raw_candidates, DesignSystem design_system) -> void
      def compile_candidates(raw_candidates, design_system)
        raw_candidates.each do |raw_candidate|
          design_system.parse_candidate(raw_candidate)
        end
      end
    end
  end
end
