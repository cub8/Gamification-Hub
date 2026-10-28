# frozen_string_literal: true

module Csv
  class BadgesImport
    Row = Data.define(:index, :name, :didactic_description, :story_description, :discount, :icon_glyph)

    HEADERS = %w[nazwa opis_dydaktyczny opis_fabularny zniżka ikona].freeze

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
        index:                index,
        name:                 row['nazwa'],
        didactic_description: row['opis_dydaktyczny'],
        story_description:    row['opis_fabularny'].presence,
        discount:             row['zniżka'],
        icon_glyph:           icon_glyph(row['ikona']),
      )
    end

    def icon_glyph(value)
      return value if Glyphs::BADGE.include?(value)

      Glyphs::BADGE.first
    end
  end
end
