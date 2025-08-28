# frozen_string_literal: true

require "rspec/core/formatters/base_formatter"

class SimpleResultFormatter < RSpec::Core::Formatters::BaseFormatter
  RSpec::Core::Formatters.register self, :example_started, :example_passed, :example_failed, :example_pending, :dump_summary

  # ステータス定数
  STATUS_PASSED = "✅"
  STATUS_FAILED = "❌"
  STATUS_PENDING = "⏸️"

  # デフォルト値定数
  DEFAULT_ASSERTION_COUNT = 1

  def initialize(output)
    super
    @examples = []
    @total_assertions = 0
    @failed_assertions = 0
  end

  def example_started(_notification)
    # テスト開始時の処理（現在は何もしない）
  end

  def example_passed(notification)
    record_example_result(notification, STATUS_PASSED, failed_count: 0)
  end

  def example_failed(notification)
    assertion_count = count_expectations_in_example(notification.example)
    failed_count = count_failed_expectations(notification)

    record_example_result(notification, STATUS_FAILED,
                          assertion_count: assertion_count,
                          failed_count: failed_count)
  end

  def example_pending(notification)
    record_example_result(notification, STATUS_PENDING, failed_count: 0)
  end

  private

  # テスト結果を記録する共通メソッド
  def record_example_result(notification, status, assertion_count: nil, failed_count: 0)
    assertion_count ||= count_expectations_in_example(notification.example)

    @total_assertions += assertion_count
    @failed_assertions += failed_count

    @examples << {
      status: status,
      description: notification.example.description,
      assertion_count: assertion_count,
      failed_assertion_count: failed_count
    }
  rescue StandardError => e
    handle_error("record_example_result", e, notification, status, failed_count)
  end

  # エラーハンドリングの共通メソッド
  def handle_error(method_name, error, notification, status, failed_count)
    debug_log("Error in #{method_name}: #{error.message}")

    @total_assertions += DEFAULT_ASSERTION_COUNT
    @failed_assertions += failed_count

    @examples << {
      status: status,
      description: notification.example.description,
      assertion_count: DEFAULT_ASSERTION_COUNT,
      failed_assertion_count: failed_count
    }
  end

  # aggregate_failuresから失敗したexpectationの数を取得
  def count_failed_expectations(notification)
    exception = notification.exception

    if exception&.respond_to?(:all_exceptions)
      # RSpec::Expectations::MultipleExpectationsNotMetError
      exception.all_exceptions.count
    elsif exception&.message&.include?("Got ")
      # aggregate_failuresのメッセージから推定
      failure_lines = exception.message.scan(/^\s*\d+\)/).count
      [failure_lines, DEFAULT_ASSERTION_COUNT].max
    else
      # 通常のエラーは1つの失敗
      DEFAULT_ASSERTION_COUNT
    end
  rescue StandardError => e
    debug_log("Error counting failed expectations: #{e.message}")
    DEFAULT_ASSERTION_COUNT
  end

  # テストのソースコードからexpectationの数を取得
  def count_expectations_in_example(example)
    source_location = example.metadata[:location]
    return DEFAULT_ASSERTION_COUNT unless source_location

    file_path, line_number = parse_source_location(source_location)
    file_lines = File.readlines(file_path)
    content = extract_example_content(file_lines, line_number)

    count_expectations_in_content(content)
  rescue StandardError => e
    debug_log("Error parsing expectations: #{e.message}")
    DEFAULT_ASSERTION_COUNT
  end

  # ソースの場所情報を解析
  def parse_source_location(location)
    file_path, line_number = location.split(":")
    [file_path, line_number.to_i]
  end

  # テストの内容を抽出
  def extract_example_content(file_lines, line_number)
    start_line = line_number - 1 # 0-indexed
    end_line = find_end_of_example(file_lines, start_line)
    file_lines[start_line..end_line].join
  end

  # コンテンツ内のexpectationをカウント
  def count_expectations_in_content(content)
    expect_count = content.scan("expect(").count

    # .each do |candidate| パターンの特別処理
    expect_count = count_array_elements(content) || expect_count if has_each_with_single_expect?(content, expect_count)

    [expect_count, DEFAULT_ASSERTION_COUNT].max
  end

  # .each do |...| ... expect(...) パターンの検出
  def has_each_with_single_expect?(content, expect_count)
    content.include?(".each do |") && expect_count == 1
  end

  # 配列要素数をカウント
  def count_array_elements(content)
    # candidates = [ ... ] の形式を検出
    candidates_match = content.match(/candidates\s*=\s*\[(.*?)\]/m)
    return candidates_match[1].scan(/"[^"]*"/).count if candidates_match

    # [ "item1", "item2", ... ] の形式を検出
    array_match = content.match(/\[\s*([^\[\]]*)\s*\]/m)
    if array_match
      string_count = array_match[1].scan(/"[^"]*"/).count
      return string_count if string_count > 1
    end

    nil
  end

  # テストブロックの終了位置を見つける
  def find_end_of_example(lines, start_line)
    start_indent = get_line_indent(lines[start_line])

    ((start_line + 1)...lines.length).each do |i|
      line = lines[i].strip
      next if skip_line?(line)

      current_indent = get_line_indent(lines[i])

      if same_or_less_indent?(current_indent, start_indent) &&
         end_marker_line?(line)
        return i - 1
      end
    end

    lines.length - 1
  end

  # 行のインデントレベルを取得
  def get_line_indent(line)
    line.match(/^\s*/)[0].length
  end

  # スキップすべき行かチェック
  def skip_line?(line)
    line.empty? || line.start_with?("#")
  end

  # 同じかそれ以下のインデントかチェック
  def same_or_less_indent?(current, start)
    current <= start
  end

  # 終了マーカーの行かチェック
  def end_marker_line?(line)
    line.start_with?("it ", "end")
  end

  # デバッグログ出力
  def debug_log(message)
    puts message if ENV["DEBUG"]
  end

  public

  # サマリー出力
  def dump_summary(summary)
    output_individual_results
    output_overall_summary(summary)
  end

  private

  # 個別の結果を出力
  def output_individual_results
    @examples.each do |example|
      output.puts format_example_result(example)
    end
  end

  # テスト結果の文字列をフォーマット
  def format_example_result(example)
    if example[:assertion_count] > 1
      format_detailed_result(example)
    else
      format_simple_result(example)
    end
  end

  # 詳細結果のフォーマット
  def format_detailed_result(example)
    passed = example[:assertion_count] - example[:failed_assertion_count]
    percentage = (passed.to_f / example[:assertion_count] * 100).round(1)

    "#{example[:status]}: #{example[:description]} " \
      "(#{passed}/#{example[:assertion_count]} expects, #{percentage}%)"
  end

  # 単純結果のフォーマット
  def format_simple_result(example)
    "#{example[:status]}: #{example[:description]}"
  end

  # 全体サマリーを出力
  def output_overall_summary(summary)
    example_stats = calculate_example_stats(summary)
    assertion_stats = calculate_assertion_stats

    output.puts "\n📊 Results Summary:"
    output.puts "Examples: #{example_stats[:percentage]}% passed (#{example_stats[:passed]}/#{example_stats[:total]})"
    output.puts "Expects: #{assertion_stats[:percentage]}% passed (#{assertion_stats[:passed]}/#{assertion_stats[:total]})"
    output.puts "Overall: #{assertion_stats[:percentage]}%"
  end

  # テストの統計を計算
  def calculate_example_stats(summary)
    total = summary.example_count
    failed = summary.failure_count
    passed = total - failed
    percentage = (passed.to_f / total * 100).round(2)

    { total: total, passed: passed, percentage: percentage }
  end

  # アサーションの統計を計算
  def calculate_assertion_stats
    passed = @total_assertions - @failed_assertions
    percentage = if @total_assertions > 0
                   (passed.to_f / @total_assertions * 100).round(2)
                 else
                   0
                 end

    { total: @total_assertions, passed: passed, percentage: percentage }
  end
end
