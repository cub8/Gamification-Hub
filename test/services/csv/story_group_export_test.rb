# frozen_string_literal: true

require 'test_helper'

module Csv
  class StoryGroupExportTest < ActiveSupport::TestCase
    setup do
      @story_group = FactoryBot.create(:story_group)
    end

    test 'supports? recognizes only the four known resources' do
      assert StoryGroupExport.supports?('ranks')
      assert StoryGroupExport.supports?('badges')
      assert StoryGroupExport.supports?('items')
      assert StoryGroupExport.supports?('templates')
      assert_not StoryGroupExport.supports?('students')
      assert_not StoryGroupExport.supports?('')
    end

    test 'csv_for dispatches to the matching exporter' do
      FactoryBot.create(:rank, story_group: @story_group, name: 'Złoto')

      csv = StoryGroupExport.new(story_group: @story_group).csv_for('ranks')

      assert_includes csv, 'Złoto'
    end

    test 'LABELS has a Polish label for every supported resource' do
      assert_equal StoryGroupExport::RESOURCES.sort, StoryGroupExport::LABELS.keys.sort
    end
  end
end
