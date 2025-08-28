# frozen_string_literal: true

require "rspec/core/formatters/base_formatter"

class SimpleResultFormatter < RSpec::Core::Formatters::BaseFormatter
  RSpec::Core::Formatters.register self, :example_started, :example_passed, :example_failed, :example_pending, :dump_summary

  def initialize(output)
    super
    @examples = []
    @total_assertions = 0
    @failed_assertions = 0
  end

  def example_started(_notification)
    # テストの開始時にassertionカウントをリセット
  end

  def example_passed(notification)
    # パスしたテストから期待値の数を推定
    assertion_count = count_expectations_in_example(notification.example)
    @total_assertions += assertion_count

    @examples << {
      status: "✅",
      description: notification.example.description,
      assertion_count: assertion_count,
      failed_assertion_count: 0
    }
  end

  def example_failed(notification)
    # 失敗したテストから期待値の数を推定
    assertion_count = count_expectations_in_example(notification.example)
    failed_count = 1 # 少なくとも1つは失敗している

    @total_assertions += assertion_count
    @failed_assertions += failed_count

    @examples << {
      status: "❌",
      description: notification.example.description,
      assertion_count: assertion_count,
      failed_assertion_count: failed_count
    }
  end

  def example_pending(notification)
    assertion_count = count_expectations_in_example(notification.example)
    @total_assertions += assertion_count

    @examples << {
      status: "⏸️",
      description: notification.example.description,
      assertion_count: assertion_count,
      failed_assertion_count: 0
    }
  end

  def count_expectations_in_example(example)
    # テストのソースコードから expect の数をカウント
    source_location = example.metadata[:location]
    return 1 unless source_location

    file_path, line_number = source_location.split(":")
    line_number = line_number.to_i

    begin
      # ファイルを読んでexpectの数をカウント
      file_lines = File.readlines(file_path)

      # itブロックの開始行から次のitまたはendまでの行を取得
      start_line = line_number - 1 # 0-indexed
      end_line = find_end_of_example(file_lines, start_line)

      example_lines = file_lines[start_line..end_line]
      expect_count = example_lines.join.scan("expect(").count

      # 最小1つは期待値があるとする
      [expect_count, 1].max
    rescue StandardError
      # エラーが発生した場合は1とする
      1
    end
  end

  def find_end_of_example(lines, start_line)
    # 開始行のインデントレベルを取得
    start_indent = lines[start_line].match(/^\s*/)[0].length

    ((start_line + 1)...lines.length).each do |i|
      line = lines[i].strip
      next if line.empty? || line.start_with?("#")

      current_indent = lines[i].match(/^\s*/)[0].length

      # 同じレベルの 'it' または 'end' が見つかったら終了
      return i - 1 if current_indent <= start_indent && line.start_with?("it ", "end")
    end

    # 見つからなかった場合は、ファイルの最後まで
    lines.length - 1
  end

  def dump_summary(summary)
    @examples.each do |example|
      if example[:assertion_count] > 1
        passed_assertions = example[:assertion_count] - example[:failed_assertion_count]
        assertion_percentage = (passed_assertions.to_f / example[:assertion_count] * 100).round(1)
        output.puts "#{example[:status]}: #{example[:description]} (#{passed_assertions}/#{example[:assertion_count]} expects, #{assertion_percentage}%)"
      else
        output.puts "#{example[:status]}: #{example[:description]}"
      end
    end

    total_examples = summary.example_count
    failed_examples = summary.failure_count
    passed_examples = total_examples - failed_examples
    example_percentage = (passed_examples.to_f / total_examples * 100).round(2)

    passed_assertions = @total_assertions - @failed_assertions
    assertion_percentage = @total_assertions > 0 ? (passed_assertions.to_f / @total_assertions * 100).round(2) : 0

    output.puts "\n📊 Results Summary:"
    output.puts "Examples: #{example_percentage}% passed (#{passed_examples}/#{total_examples})"
    output.puts "Expects: #{assertion_percentage}% passed (#{passed_assertions}/#{@total_assertions})"
    output.puts "Overall: #{assertion_percentage}%"
  end
end
