# frozen_string_literal: true

require 'test_helper'

module Csv
  class RanksImportTest < ActiveSupport::TestCase
    test 'parses rows into the StarterPack-compatible Rank shape, indexed from zero' do
      file = StringIO.new(<<~CSV)
        nazwa,próg_waluty,zniżka,ikona
        Srebro,200,5,chev1
        Złoto,500,15,chev2
      CSV

      rows = RanksImport.new(file: file).call

      assert_equal 2, rows.size
      assert_equal RanksImport::Row.new(index: 0, name: 'Srebro', threshold: '200', discount: '5',
                                        icon_glyph: 'chev1',), rows[0]
      assert_equal RanksImport::Row.new(index: 1, name: 'Złoto', threshold: '500', discount: '15',
                                        icon_glyph: 'chev2',), rows[1]
    end

    test 'falls back to a default glyph for a blank icon cell, so the row never fails validation for it' do
      file = StringIO.new(<<~CSV)
        nazwa,próg_waluty,zniżka,ikona
        Srebro,200,5,
      CSV

      row = RanksImport.new(file: file).call.first

      assert_equal Glyphs::RANK.first, row.icon_glyph
    end

    test 'falls back to a default glyph for an unrecognized icon key' do
      file = StringIO.new(<<~CSV)
        nazwa,próg_waluty,zniżka,ikona
        Srebro,200,5,not-a-real-glyph
      CSV

      row = RanksImport.new(file: file).call.first

      assert_equal Glyphs::RANK.first, row.icon_glyph
    end

    test 'strips a leading UTF-8 BOM, matching files produced by the export feature' do
      csv = <<~CSV
        nazwa,próg_waluty,zniżka,ikona
        Srebro,200,5,chev1
      CSV
      file = StringIO.new("#{Csv::Utf8Bom}#{csv}")

      row = RanksImport.new(file: file).call.first

      assert_equal 'nazwa', RanksImport::HEADERS.first
      assert_equal 'Srebro', row.name
    end

    test 'returns an empty array for a file with only a header row' do
      file = StringIO.new("nazwa,próg_waluty,zniżka,ikona\n")

      assert_empty RanksImport.new(file: file).call
    end

    test 'raises Csv::MalformedFile for content that is not valid CSV' do
      file = StringIO.new(%("unterminated quote,next))

      assert_raises(Csv::MalformedFile) { RanksImport.new(file: file).call }
    end
  end
end
