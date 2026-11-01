# frozen_string_literal: true

module Csv
  # Spreadsheet apps evaluate cells that start with = + - @ (or a tab / carriage return) as formulas.
  # Exports prefix such text with an apostrophe, which Excel and Sheets display as plain text;
  # imports strip that prefix so a round trip returns the original value.
  module FormulaGuard
    TRIGGERS = ['=', '+', '-', '@', "\t", "\r"].freeze
    ESCAPE = "'"

    class << self
      def escape(value)
        return value unless value.is_a?(String) && value.start_with?(*TRIGGERS)

        "#{ESCAPE}#{value}"
      end

      def unescape(value)
        return value unless value.is_a?(String) && value.start_with?(ESCAPE) && value[1]&.start_with?(*TRIGGERS)

        value.delete_prefix(ESCAPE)
      end

      def row(values) = values.map { |value| escape(value) }
    end
  end
end
