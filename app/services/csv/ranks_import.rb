# frozen_string_literal: true

module Csv
  class RanksImport
    include ParsesRows

    CSV_SCOPE = 'ranks'

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

    def row_for(row, index)
      Row.new(
        index:      index,
        name:       column(row, :name),
        threshold:  column(row, :threshold),
        discount:   column(row, :discount),
        icon_glyph: icon_glyph(column(row, :icon)),
      )
    end

    def icon_glyph(value)
      return value if Glyphs::RANK.include?(value)

      Glyphs::RANK.first
    end
  end
end
