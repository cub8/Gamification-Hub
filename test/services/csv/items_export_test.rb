# frozen_string_literal: true

require 'test_helper'

module Csv
  class ItemsExportTest < ActiveSupport::TestCase
    setup do
      @story_group = FactoryBot.create(:story_group)
    end

    test 'exports headers, booleans as tak/nie, and rank/badge references' do
      rank = FactoryBot.create(:rank, story_group: @story_group, name: 'Złoto', required_currency_value: 500)
      badge_a = FactoryBot.create(:badge, story_group: @story_group, name: 'Zuch')
      badge_b = FactoryBot.create(:badge, story_group: @story_group, name: 'Asceta')

      item = FactoryBot.create(:item, story_group: @story_group, name: 'Tarcza', price: 42,
                               can_buy_at_0_lives: true, unlock_rank: rank, min_rank_for_discount: rank,)
      item.unlock_badges << badge_a
      item.discount_badges << badge_a
      item.discount_badges << badge_b

      rows = CSV.parse(ItemsExport.new(story_group: @story_group).call, headers: true)
      row = rows.first

      assert_equal %w[
        nazwa
        opis_dydaktyczny
        opis_fabularny
        cena
        można_kupić_przy_0_życiach
        ikona
        ranga_odblokowująca
        ranga_minimalna_dla_zniżki
        odznaki_odblokowujące
        odznaki_dla_zniżki
      ], rows.headers
      assert_equal 'Tarcza', row['nazwa']
      assert_equal '42', row['cena']
      assert_equal 'tak', row['można_kupić_przy_0_życiach']
      assert_equal 'Złoto (500)', row['ranga_odblokowująca']
      assert_equal 'Złoto (500)', row['ranga_minimalna_dla_zniżki']
      assert_equal 'Zuch', row['odznaki_odblokowujące']
      assert_equal 'Zuch;Asceta', row['odznaki_dla_zniżki']
    end

    test 'exports English headers and "yes" for the boolean when the current locale is English' do
      item = FactoryBot.create(:item, story_group: @story_group, can_buy_at_0_lives: true)

      rows = I18n.with_locale(:en) { CSV.parse(ItemsExport.new(story_group: @story_group).call, headers: true) }

      assert_equal %w[
        name
        didactic_description
        story_description
        price
        can_buy_at_0_lives
        icon
        unlock_rank
        min_rank_for_discount
        unlock_badges
        discount_badges
      ], rows.headers
      assert_equal 'yes', rows.first['can_buy_at_0_lives']
      assert_equal item.name, rows.first['name']
    end

    test 'blank rank/badge columns when none are set, nie for false boolean' do
      FactoryBot.create(:item, story_group: @story_group, can_buy_at_0_lives: false)

      row = CSV.parse(ItemsExport.new(story_group: @story_group).call, headers: true).first

      assert_equal 'nie', row['można_kupić_przy_0_życiach']
      assert_nil row['ranga_odblokowująca']
      assert_nil row['ranga_minimalna_dla_zniżki']
      assert_nil row['odznaki_odblokowujące']
      assert_nil row['odznaki_dla_zniżki']
    end

    test 'blank ikona when a custom icon is attached instead of a glyph' do
      item = FactoryBot.build(:item, story_group: @story_group, icon_glyph: nil)
      item.icon.attach(io: File.open(file_fixture('rank_art.png')), filename: 'art.png', content_type: 'image/png')
      item.save!

      row = CSV.parse(ItemsExport.new(story_group: @story_group).call, headers: true).first

      assert_nil row['ikona']
    end

    test 'excludes soft-deleted items' do
      deleted = FactoryBot.create(:item, story_group: @story_group)
      deleted.soft_delete!

      rows = CSV.parse(ItemsExport.new(story_group: @story_group).call, headers: true)

      assert_empty rows
    end
  end
end
