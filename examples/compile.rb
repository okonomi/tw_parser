# frozen_string_literal: true

require "tw_parser/compile/compiler"
require "tw_parser/design_system"

design_system = TwParser::DesignSystem.build

compiler = TwParser::Compile::Compiler.new
compiler.compile_candidates(["flex"], design_system)
