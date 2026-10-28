# frozen_string_literal: true

module Csv
  class RanksImport
    Row = Data.define(:index, :name, :threshold, :discount, :icon_glyph)

    HEADERS = %w[nazwa próg_waluty zniżka ikona].freeze

    def initialize(file:)
      @file = file
    end

    def call
      rows.each_with_index.map { |row, index| row_for(row, index) }
    rescue ::CSV::MalformedCSVError
      raise Csv::MalformedFile
    end

    private

    def rows
      CSV.parse(content, headers: true)
    end

    def content
      @file.read.force_encoding(Encoding::UTF_8).delete_prefix(Csv::Utf8Bom)
    end

    def row_for(row, index)
      Row.new(
        index:      index,
        name:       row['nazwa'],
        threshold:  row['próg_waluty'],
        discount:   row['zniżka'],
        icon_glyph: icon_glyph(row['ikona']),
      )
    end

    def icon_glyph(value)
      return value if Glyphs::RANK.include?(value)

      Glyphs::RANK.first
    end
  end
end
