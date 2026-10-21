# frozen_string_literal: true

require 'test_helper'

module Csv
  class RanksExportTest < ActiveSupport::TestCase
    setup do
      @story_group = FactoryBot.create(:story_group)
    end

    test 'exports headers and rows ordered by threshold' do
      FactoryBot.create(:rank, story_group: @story_group, name: 'Srebro', required_currency_value: 200,
                               discount: 5, icon_glyph: 'chev1',)
      FactoryBot.create(:rank, story_group: @story_group, name: 'Złoto', required_currency_value: 500,
                               discount: 15, icon_glyph: 'chev2',)

      rows = CSV.parse(RanksExport.new(story_group: @story_group).call, headers: true)

      assert_equal %w[nazwa próg_waluty zniżka ikona], rows.headers
      assert_equal %w[Srebro 200 5 chev1], rows[0].fields
      assert_equal %w[Złoto 500 15 chev2], rows[1].fields
    end

    test 'exports an empty body when the group has no ranks' do
      rows = CSV.parse(RanksExport.new(story_group: @story_group).call, headers: true)

      assert_empty rows
    end
  end
end
