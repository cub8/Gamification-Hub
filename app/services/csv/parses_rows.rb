# frozen_string_literal: true

module Csv
  module ParsesRows
    private

    def rows
      CSV.parse(content, headers: true)
    end

    def content
      @file.rewind
      @file.read.force_encoding(Encoding::UTF_8).delete_prefix(Csv::Utf8Bom)
    end

    def column(row, key)
      Localized.column(row, "#{self.class::CSV_SCOPE}.csv_columns.#{key}")
    end
  end
end
