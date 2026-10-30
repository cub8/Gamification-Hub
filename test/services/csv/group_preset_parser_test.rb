# frozen_string_literal: true

require 'test_helper'

module Csv
  class GroupPresetParserTest < ActiveSupport::TestCase
    def ranks_file
      StringIO.new(<<~CSV)
        nazwa,próg_waluty,zniżka,ikona
        Złoto,500,10,chev1
      CSV
    end

    def badges_file
      StringIO.new(<<~CSV)
        nazwa,opis_dydaktyczny,opis_fabularny,zniżka,ikona
        Zuch,Opis,,5,rabbit
      CSV
    end

    def items_file
      StringIO.new(<<~CSV)
        nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
        Tarcza,Opis,,42,nie,shield,Złoto (500),,Zuch,
      CSV
    end

    test 'parses only the files that were provided, leaving the rest empty' do
      preset = GroupPresetParser.new({ ranks: ranks_file }).call

      assert_equal 1, preset.ranks.size
      assert_empty preset.badges
      assert_empty preset.items
      assert_empty preset.templates
    end

    test 'resolves item rank/badge references against the ranks and badges provided in the same call' do
      preset = GroupPresetParser.new({ ranks: ranks_file, badges: badges_file, items: items_file }).call

      item = preset.items.first
      assert_equal 0, item.unlock_rank
      assert_equal [0], item.unlock_badges
    end

    test 'returns an entirely empty preset when no files are given' do
      preset = GroupPresetParser.new({}).call

      assert_not preset.any?
    end

    test 'collects unresolved item rank/badge references as preset warnings instead of raising' do
      file = StringIO.new(<<~CSV)
        nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
        Tarcza,Opis,,42,nie,shield,Widmo (999),,,
      CSV

      preset = GroupPresetParser.new({ items: file }).call

      assert_nil preset.items.first.unlock_rank
      assert_equal 1, preset.warnings.size
    end

    test 'resolves item references against ranks/badges already in the story group when given one, ' \
         'without needing those files in the same upload' do
      story_group = FactoryBot.create(:story_group)
      FactoryBot.create(:rank, story_group: story_group, name: 'Złoto', required_currency_value: 500)
      FactoryBot.create(:badge, story_group: story_group, name: 'Zuch')

      preset = GroupPresetParser.new({ items: items_file }, story_group: story_group).call

      item = preset.items.first
      assert_kind_of Rank, item.unlock_rank
      assert_equal 'Złoto', item.unlock_rank.name
      assert_equal 1, item.unlock_badges.size
      assert_kind_of Badge, item.unlock_badges.first
    end
  end
end
