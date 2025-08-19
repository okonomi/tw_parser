# frozen_string_literal: true

require 'rspec/core/formatters/base_formatter'

class SimpleResultFormatter < RSpec::Core::Formatters::BaseFormatter
  RSpec::Core::Formatters.register self, :example_passed, :example_failed, :example_pending, :dump_summary

  def initialize(output)
    super
    @examples = []
  end

  def example_passed(notification)
    @examples << { status: '✅', description: notification.example.description }
  end

  def example_failed(notification)
    @examples << { status: '❌', description: notification.example.description }
  end

  def example_pending(notification)
    @examples << { status: '⏸️', description: notification.example.description }
  end

  def dump_summary(summary)
    @examples.each do |example|
      output.puts "#{example[:status]}: #{example[:description]}"
    end

    total    = summary.example_count
    failures = summary.failure_count
    passed   = total - failures
    percentage = (passed.to_f / total * 100).round(2)
    output.puts "\nPass percentage: #{percentage}% (#{passed}/#{total})"
  end
end
