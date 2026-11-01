# frozen_string_literal: true

require 'test_helper'

module Csv
  # Whatever the app exports must import back unchanged, however awkward the text:
  # commas, quotes and line breaks are quoted by CSV itself, while the ";" that
  # joins badge names in an item row is kept safe by Badge forbidding it in names.
  class RoundTripTest < ActiveSupport::TestCase
    AWKWARD = "Pierwszy, drugi i \"trzeci\"\nw nowej linii; ze średnikiem, i 'apostrofem'"

    setup do
      @story_group = FactoryBot.create(:story_group)
    end

    test 'badge descriptions with commas, quotes, semicolons and line breaks survive' do
      FactoryBot.create(:badge, story_group: @story_group, name: 'Zuch, Wielki',
                                didactic_description: AWKWARD, story_description: AWKWARD,)

      row = BadgesImport.new(file: StringIO.new(BadgesExport.new(story_group: @story_group).call)).call.first

      assert_equal 'Zuch, Wielki', row.name
      assert_equal AWKWARD, row.didactic_description
      assert_equal AWKWARD, row.story_description
    end

    test 'item descriptions with commas, quotes, semicolons and line breaks survive' do
      FactoryBot.create(:item, story_group: @story_group, name: 'Tarcza, ozdobna',
                               didactic_description: AWKWARD, story_description: AWKWARD,)

      row = ItemsImport.new(file: StringIO.new(ItemsExport.new(story_group: @story_group).call)).call.first

      assert_equal 'Tarcza, ozdobna', row.name
      assert_equal AWKWARD, row.didactic_description
      assert_equal AWKWARD, row.story_description
    end

    test 'every badge on an item is recovered, including names with commas, quotes and spaces around them' do
      names  = ['Zuch', 'Zuch, Wielki', 'Asceta "Pro"', 'Poziom: 2', "Rycerz's", 'A / B']
      badges = names.map { |name| FactoryBot.create(:badge, story_group: @story_group, name: name) }
      item   = FactoryBot.create(:item, story_group: @story_group, unlock_badges: badges, discount_badges: badges)

      csv = ItemsExport.new(story_group: @story_group).call
      importer = ItemsImport.new(file: StringIO.new(csv), story_group: @story_group)
      row = importer.call.first

      assert_equal badges.sort_by(&:id), row.unlock_badges.sort_by(&:id), "item #{item.name}"
      assert_equal badges.sort_by(&:id), row.discount_badges.sort_by(&:id)
      assert_empty importer.warnings
    end

    test 'two badges with similar names are not merged into one reference' do
      zuch = FactoryBot.create(:badge, story_group: @story_group, name: 'Zuch')
      wielki = FactoryBot.create(:badge, story_group: @story_group, name: 'Zuch Wielki')
      FactoryBot.create(:item, story_group: @story_group, unlock_badges: [zuch, wielki])

      csv = ItemsExport.new(story_group: @story_group).call
      row = ItemsImport.new(file: StringIO.new(csv), story_group: @story_group).call.first

      assert_equal [zuch, wielki].sort_by(&:id), row.unlock_badges.sort_by(&:id)
    end

    test 'an item badge cell with stray spaces and empty entries still resolves' do
      zuch = FactoryBot.create(:badge, story_group: @story_group, name: 'Zuch')
      asceta = FactoryBot.create(:badge, story_group: @story_group, name: 'Asceta')
      file = StringIO.new(<<~CSV)
        nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
        Tarcza,Opis,,42,nie,shield,,,"Zuch ; ;Asceta;",
      CSV

      row = ItemsImport.new(file: file, story_group: @story_group).call.first

      assert_equal [zuch, asceta], row.unlock_badges
    end

    test 'a deleted badge is neither exported on an item nor resolved on import' do
      kept    = FactoryBot.create(:badge, story_group: @story_group, name: 'Zuch')
      removed = FactoryBot.create(:badge, story_group: @story_group, name: 'Asceta')
      FactoryBot.create(:item, story_group: @story_group, unlock_badges: [kept, removed])
      removed.soft_delete!

      file = StringIO.new(<<~CSV)
        nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
        Tarcza,Opis,,42,nie,shield,,,Zuch;Asceta,
      CSV
      importer = ItemsImport.new(file: file, story_group: @story_group)
      row = importer.call.first

      assert_equal [kept], row.unlock_badges
      assert_equal 1, importer.warnings.size
    end

    test 'template category descriptions with commas, quotes and line breaks survive' do
      template = FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: 'Lab, część 1')
      FactoryBot.create(:activity_group_template_category, activity_group_template: template,
                                                           didactic_description: AWKWARD, story_description: AWKWARD,)

      csv = TemplatesExport.new(story_group: @story_group).call
      parsed = TemplatesImport.new(file: StringIO.new(csv)).call.first

      assert_equal 'Lab, część 1', parsed.name
      assert_equal AWKWARD, parsed.categories.first.didactic_description
      assert_equal AWKWARD, parsed.categories.first.story_description
    end

    test 'a file saved with a BOM and Windows line endings imports the same as the original' do
      FactoryBot.create(:badge, story_group: @story_group, name: 'Zuch', didactic_description: 'Raz, dwa')
      csv = "#{Csv::Utf8Bom}#{BadgesExport.new(story_group: @story_group).call.gsub("\n", "\r\n")}"

      row = BadgesImport.new(file: StringIO.new(csv)).call.first

      assert_equal 'Zuch', row.name
      assert_equal 'Raz, dwa', row.didactic_description
    end
  end
end
