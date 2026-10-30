# frozen_string_literal: true

require 'test_helper'

module Csv
  class BadgesExportTest < ActiveSupport::TestCase
    setup do
      @story_group = FactoryBot.create(:story_group)
    end

    test 'exports headers and rows ordered by name' do
      FactoryBot.create(:badge, story_group: @story_group, name: 'Zuch', story_description: 'Opis fabularny',
                               didactic_description: 'Opis dydaktyczny', discount: 10, icon_glyph: 'rabbit',)
      FactoryBot.create(:badge, story_group: @story_group, name: 'Asceta', story_description: '',
                               didactic_description: 'Inny opis', discount: 5, icon_glyph: 'rabbit',)

      rows = CSV.parse(BadgesExport.new(story_group: @story_group).call, headers: true)

      assert_equal %w[nazwa opis_dydaktyczny opis_fabularny zniżka ikona], rows.headers
      assert_equal 'Asceta', rows[0]['nazwa']
      assert_equal 'Zuch', rows[1]['nazwa']
      assert_equal 'Opis fabularny', rows[1]['opis_fabularny']
    end

    test 'excludes soft-deleted badges' do
      deleted = FactoryBot.create(:badge, story_group: @story_group, name: 'Usunięta')
      deleted.soft_delete!

      rows = CSV.parse(BadgesExport.new(story_group: @story_group).call, headers: true)

      assert_empty rows
    end
  end
end
