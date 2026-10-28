# frozen_string_literal: true

require 'test_helper'

module Csv
  class ItemsImportTest < ActiveSupport::TestCase
    setup do
      @ranks = [RanksImport::Row.new(index: 0, name: 'Złoto', threshold: '500', discount: '10', icon_glyph: nil)]
      @badges = [
        BadgesImport::Row.new(index: 0, name: 'Zuch', didactic_description: '', story_description: nil,
                              discount: '5', icon_glyph: nil,),
        BadgesImport::Row.new(index: 1, name: 'Asceta', didactic_description: '', story_description: nil,
                              discount: '5', icon_glyph: nil,),
      ]
    end

    test 'resolves rank and badge labels to indexes among the already-parsed rows' do
      file = StringIO.new(<<~CSV)
        nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
        Tarcza,Opis,,42,tak,shield,Złoto (500),Złoto (500),Zuch,Zuch;Asceta
      CSV

      row = ItemsImport.new(file: file, ranks: @ranks, badges: @badges).call.first

      assert_equal 'Tarcza', row.name
      assert_equal '42', row.price
      assert_equal true, row.can_buy_at_0_lives
      assert_equal 0, row.unlock_rank
      assert_equal 0, row.min_rank_for_discount
      assert_equal [0], row.unlock_badges
      assert_equal [0, 1], row.discount_badges
    end

    test 'blank rank/badge columns and "nie" boolean parse to empty/false' do
      file = StringIO.new(<<~CSV)
        nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
        Zwykły,Opis,,10,nie,shield,,,,
      CSV

      row = ItemsImport.new(file: file, ranks: @ranks, badges: @badges).call.first

      assert_equal false, row.can_buy_at_0_lives
      assert_nil row.unlock_rank
      assert_nil row.min_rank_for_discount
      assert_empty row.unlock_badges
      assert_empty row.discount_badges
    end

    test 'skips a rank label not among the parsed ranks, leaving it blank, and records a warning' do
      file = StringIO.new(<<~CSV)
        nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
        Tarcza,Opis,,42,nie,shield,Srebro (200),,,
      CSV

      importer = ItemsImport.new(file: file, ranks: @ranks, badges: @badges)
      row = importer.call.first

      assert_nil row.unlock_rank
      assert_equal 1, importer.warnings.size
    end

    test 'skips a rank label in an unrecognized format, leaving it blank, and records a warning' do
      file = StringIO.new(<<~CSV)
        nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
        Tarcza,Opis,,42,nie,shield,Srebro,,,
      CSV

      importer = ItemsImport.new(file: file, ranks: @ranks, badges: @badges)
      row = importer.call.first

      assert_nil row.unlock_rank
      assert_equal 1, importer.warnings.size
    end

    test 'skips a badge name not among the parsed badges, leaving it out, and records a warning' do
      file = StringIO.new(<<~CSV)
        nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
        Tarcza,Opis,,42,nie,shield,,,Nieznana,
      CSV

      importer = ItemsImport.new(file: file, ranks: @ranks, badges: @badges)
      row = importer.call.first

      assert_empty row.unlock_badges
      assert_equal 1, importer.warnings.size
    end

    test 'raises Csv::MalformedFile for content that is not valid CSV' do
      file = StringIO.new(%("unterminated quote,next))

      assert_raises(Csv::MalformedFile) { ItemsImport.new(file: file).call }
    end

    test 'falls back to a default glyph for a blank icon cell' do
      file = StringIO.new(<<~CSV)
        nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
        Zwykły,Opis,,10,nie,,,,,
      CSV

      row = ItemsImport.new(file: file).call.first

      assert_equal Glyphs::ITEM.first, row.icon_glyph
    end

    test 'resolves a rank/badge reference against the story group when not present in this batch' do
      story_group = FactoryBot.create(:story_group)
      rank = FactoryBot.create(:rank, story_group: story_group, name: 'Kosmiczny Królik',
                                      required_currency_value: 40,)
      badge = FactoryBot.create(:badge, story_group: story_group, name: 'Zuch')
      file = StringIO.new(<<~CSV)
        nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
        Tarcza,Opis,,42,nie,shield,Kosmiczny Królik (40),,Zuch,
      CSV

      row = ItemsImport.new(file: file, story_group: story_group).call.first

      assert_equal rank, row.unlock_rank
      assert_equal [badge], row.unlock_badges
    end

    test 'still skips the reference, with a warning, when absent from both the batch and the story group' do
      story_group = FactoryBot.create(:story_group)
      file = StringIO.new(<<~CSV)
        nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
        Tarcza,Opis,,42,nie,shield,Widmo (999),,,
      CSV

      importer = ItemsImport.new(file: file, story_group: story_group)
      row = importer.call.first

      assert_nil row.unlock_rank
      assert_equal 1, importer.warnings.size
    end
  end
end
