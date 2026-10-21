# frozen_string_literal: true

require 'test_helper'

module Csv
  class TemplatesExportTest < ActiveSupport::TestCase
    setup do
      @story_group = FactoryBot.create(:story_group)
    end

    test 'flattens templates and categories, one row per category, grouped by nr_szablonu' do
      first = FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: 'Laboratoria')
      FactoryBot.create(:activity_group_template_category, activity_group_template: first, position: 0,
                        didactic_description: 'Obecność', reward: 5,)
      FactoryBot.create(:activity_group_template_category, activity_group_template: first, position: 1,
                        didactic_description: 'Zadanie', reward: 10,)

      second = FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: 'Wykłady')
      FactoryBot.create(:activity_group_template_category, activity_group_template: second, position: 0,
                        didactic_description: 'Quiz', reward: 3,)

      rows = CSV.parse(TemplatesExport.new(story_group: @story_group).call, headers: true)

      assert_equal %w[nr_szablonu szablon pozycja opis_dydaktyczny opis_fabularny nagroda], rows.headers
      assert_equal 3, rows.size
      assert_equal(%w[1 1 2], rows.map { |row| row['nr_szablonu'] })
      assert_equal(%w[Laboratoria Laboratoria Wykłady], rows.map { |row| row['szablon'] })
      assert_equal(%w[Obecność Zadanie Quiz], rows.map { |row| row['opis_dydaktyczny'] })
    end

    test 'emits one blank-category row for a template with no categories' do
      FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: 'Pusty')

      rows = CSV.parse(TemplatesExport.new(story_group: @story_group).call, headers: true)

      assert_equal 1, rows.size
      assert_equal 'Pusty', rows.first['szablon']
      assert_nil rows.first['opis_dydaktyczny']
    end

    test 'excludes soft-deleted templates' do
      deleted = FactoryBot.create(:activity_group_template, story_group: @story_group)
      deleted.soft_delete!

      rows = CSV.parse(TemplatesExport.new(story_group: @story_group).call, headers: true)

      assert_empty rows
    end
  end
end
