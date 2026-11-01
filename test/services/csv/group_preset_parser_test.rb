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

    test 'warns when a ranks, badges or items name already exists in the group, ignoring case' do
      story_group = FactoryBot.create(:story_group)
      FactoryBot.create(:rank, story_group: story_group, name: 'złoto')
      FactoryBot.create(:badge, story_group: story_group, name: 'ZUCH')
      FactoryBot.create(:item, story_group: story_group, name: 'Tarcza')

      preset = GroupPresetParser.new({ ranks: ranks_file, badges: badges_file, items: items_file },
                                     story_group: story_group,).call

      assert_equal 3, preset.warnings.size
      assert_equal 1, preset.ranks.size
    end

    test 'does not warn about duplicates when nothing with that name exists yet' do
      story_group = FactoryBot.create(:story_group)

      preset = GroupPresetParser.new({ ranks: ranks_file }, story_group: story_group).call

      assert_empty preset.warnings
    end

    test 'warns about an existing template name' do
      story_group = FactoryBot.create(:story_group)
      FactoryBot.create(:activity_group_template, story_group: story_group, base_name: 'Lab')
      file = StringIO.new(<<~CSV)
        nr_szablonu,szablon,pozycja,opis_dydaktyczny,opis_fabularny,nagroda
        1,Lab,1,Quiz,,3
      CSV

      preset = GroupPresetParser.new({ templates: file }, story_group: story_group).call

      assert_equal 1, preset.templates.size
      assert_equal 1, preset.warnings.size
    end

    test 'skips a template without categories and warns about it' do
      file = StringIO.new(<<~CSV)
        nr_szablonu,szablon,pozycja,opis_dydaktyczny,opis_fabularny,nagroda
        1,Pusty,,,,
        2,Pełny,1,Quiz,,3
      CSV

      preset = GroupPresetParser.new({ templates: file }).call

      assert_equal ['Pełny'], preset.templates.map(&:name)
      assert_equal 1, preset.warnings.size
    end
  end
end
