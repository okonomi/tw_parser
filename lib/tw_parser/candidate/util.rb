# rbs_inline: enabled
# frozen_string_literal: true

module TwParser
  module Candidate
    class Util
      class << self
        #: (untyped candidate) -> Hash[Symbol, untyped]
        def extract_candidate_info(candidate)
          class_name = candidate.class.name.split("::").last
          kind = class_name.gsub(/([^A-Z])([A-Z])/, '\1_\2')
                           .split("_")
                           .first
                           .downcase
                           .to_sym

          attributes = candidate.to_h.transform_values do |value|
            if value.is_a?(Array)
              value.map { extract_candidate_info(_1) }
            else
              value.class.name.start_with?("TwParser::Candidate::") ? extract_candidate_info(value) : value
            end
          end

          { kind: kind }.merge(attributes)
        end

        #: (String str) -> String
        def unsurround(str)
          str.slice(1..-2) || ""
        end
      end
    end
  end
end
