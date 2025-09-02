# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["--exclude-pattern", "spec/compatibility/**/*_spec.rb"]
end

RSpec::Core::RakeTask.new(:spec_compatibility) do |t|
  t.rspec_opts = ["--pattern", "spec/compatibility/**/*_spec.rb", "--format", "SimpleResultFormatter"]
  t.fail_on_error = false
end

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]
