# frozen_string_literal: true

require 'test_helper'

module Csv
  class BadgesImportTest < ActiveSupport::TestCase
    test 'parses rows into the StarterPack-compatible Badge shape, indexed from zero' do
      file = StringIO.new(<<~CSV)
        nazwa,opis_dydaktyczny,opis_fabularny,zniżka,ikona
        Zuch,Opis dydaktyczny,Opis fabularny,10,rabbit
        Asceta,Inny opis,,5,
      CSV

      rows = BadgesImport.new(file: file).call

      assert_equal 2, rows.size
      assert_equal BadgesImport::Row.new(index: 0, name: 'Zuch', didactic_description: 'Opis dydaktyczny',
                                         story_description: 'Opis fabularny', discount: '10',
                                         icon_glyph: 'rabbit',), rows[0]
      assert_equal BadgesImport::Row.new(index: 1, name: 'Asceta', didactic_description: 'Inny opis',
                                         story_description: nil, discount: '5',
                                         icon_glyph: Glyphs::BADGE.first,), rows[1]
    end

    test 'raises Csv::MalformedFile for content that is not valid CSV' do
      file = StringIO.new(%("unterminated quote,next))

      assert_raises(Csv::MalformedFile) { BadgesImport.new(file: file).call }
    end
  end
end
