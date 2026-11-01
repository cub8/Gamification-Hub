# frozen_string_literal: true

require 'test_helper'

module Csv
  class PresetParamsTest < ActiveSupport::TestCase
    setup do
      @story_group = FactoryBot.create(:story_group)
    end

    test 'rebuilds ranks, badges and templates from nested params' do
      setup = ActionController::Parameters.new(
        ranks:     { '0' => { name: 'Złoto', threshold: '500', discount: '15', icon_glyph: 'chev2' } },
        badges:    { '0' => { name: 'Zuch', didactic_description: 'Opis', discount: '5', icon_glyph: 'rabbit' } },
        templates: {
          '0' => {
            name:       'Laboratoria',
            categories: { '0' => { didactic_description: 'Obecność', reward: '5' } },
          },
        },
      )

      preset = PresetParams.new(setup, story_group: @story_group).call

      assert_equal 'Złoto', preset.ranks.first.name
      assert_equal 'Zuch', preset.badges.first.name
      assert_equal 'Laboratoria', preset.templates.first.name
      assert_equal 'Obecność', preset.templates.first.categories.first.didactic_description
    end

    test 'resolves a "batch:" item reference to the integer index' do
      setup = ActionController::Parameters.new(
        items: { '0' => { name: 'Tarcza', price: '10', unlock_rank: 'batch:1' } },
      )

      item = PresetParams.new(setup, story_group: @story_group).call.items.first

      assert_equal 1, item.unlock_rank
    end

    test 'resolves an "existing:" item reference to the persisted record in the same story group' do
      rank = FactoryBot.create(:rank, story_group: @story_group)
      setup = ActionController::Parameters.new(
        items: { '0' => { name: 'Tarcza', price: '10', unlock_rank: "existing:#{rank.id}" } },
      )

      item = PresetParams.new(setup, story_group: @story_group).call.items.first

      assert_equal rank, item.unlock_rank
    end

    test 'does not resolve an "existing:" reference to a record from a different story group' do
      other_group = FactoryBot.create(:story_group)
      foreign_rank = FactoryBot.create(:rank, story_group: other_group)
      setup = ActionController::Parameters.new(
        items: { '0' => { name: 'Tarcza', price: '10', unlock_rank: "existing:#{foreign_rank.id}" } },
      )

      item = PresetParams.new(setup, story_group: @story_group).call.items.first

      assert_nil item.unlock_rank
    end

    test 'resolves an array of badge references, dropping blanks' do
      badge = FactoryBot.create(:badge, story_group: @story_group)
      setup = ActionController::Parameters.new(
        items: { '0' => { name: 'Tarcza', price: '10', unlock_badges: ['', "existing:#{badge.id}", 'batch:0'] } },
      )

      item = PresetParams.new(setup, story_group: @story_group).call.items.first

      assert_equal [badge, 0], item.unlock_badges
    end

    test 'carries warnings through untouched' do
      setup = ActionController::Parameters.new(warnings: ['Coś nie zostało rozpoznane.'])

      preset = PresetParams.new(setup, story_group: @story_group).call

      assert_equal ['Coś nie zostało rozpoznane.'], preset.warnings
    end

    test 'returns an empty preset for blank setup' do
      preset = PresetParams.new(nil, story_group: @story_group).call

      assert preset.none?
    end
  end
end
