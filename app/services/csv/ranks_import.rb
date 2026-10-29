# frozen_string_literal: true

module Csv
  class RanksImport
    Row = Data.define(:index, :name, :threshold, :discount, :icon_glyph)

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
      @file.rewind
      @file.read.force_encoding(Encoding::UTF_8).delete_prefix(Csv::Utf8Bom)
    end

    def row_for(row, index)
      Row.new(
        index:      index,
        name:       column(row, :name),
        threshold:  column(row, :threshold),
        discount:   column(row, :discount),
        icon_glyph: icon_glyph(column(row, :icon)),
      )
    end

    def column(row, key)
      Localized.column(row, "ranks.csv_columns.#{key}")
    end

    def icon_glyph(value)
      return value if Glyphs::RANK.include?(value)

      Glyphs::RANK.first
    end
  end
end
