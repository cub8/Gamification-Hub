# frozen_string_literal: true

require 'test_helper'

class ActivityGroupBuilderTest < ActiveSupport::TestCase
  setup do
    @story_group = FactoryBot.create(:story_group)
    @template = FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: 'Lab')
    FactoryBot.create(:activity_group_template_category,
                      activity_group_template: @template,
                      story_description:       'Story 1',
                      didactic_description:    'Task 1',
                      reward:                  10,
                      position:                0,)
    FactoryBot.create(:activity_group_template_category,
                      activity_group_template: @template,
                      story_description:       'Story 2',
                      didactic_description:    'Task 2',
                      reward:                  20,
                      position:                1,)
    @builder = ActivityGroupBuilder.new(story_group: @story_group, template: @template)
  end

  test 'build creates one group with given name' do
    assert_difference('ActivityGroup.count', 1) do
      @builder.build(name: 'Lab 1')
    end

    group = ActivityGroup.last!
    assert_equal 'Lab 1', group.name
    assert_equal @template, group.activity_group_template
  end

  test 'build copies categories from template' do
    @builder.build(name: 'Lab 1')
    group = ActivityGroup.last!

    assert_equal 2, group.activity_group_categories.count
    assert_equal 'Task 1', group.activity_group_categories.first.didactic_description
    assert_equal 10, group.activity_group_categories.first.reward
    assert_equal 'Task 2', group.activity_group_categories.second.didactic_description
    assert_equal 20, group.activity_group_categories.second.reward
  end

  test 'build_many creates correct number of groups' do
    assert_difference('ActivityGroup.count', 3) do
      @builder.build_many(count: 3)
    end
  end

  test 'build_many names groups sequentially from 1' do
    @builder.build_many(count: 3)
    names = ActivityGroup.last(3).map(&:name)

    assert_includes names, 'Lab 1'
    assert_includes names, 'Lab 2'
    assert_includes names, 'Lab 3'
  end

  test 'build_many continues numbering from existing groups' do
    FactoryBot.create(:activity_group, story_group: @story_group, activity_group_template: @template, name: 'Lab 2')
    @builder.build_many(count: 2)
    names = ActivityGroup.last(2).map(&:name)

    assert_includes names, 'Lab 3'
    assert_includes names, 'Lab 4'
  end

  test 'build_many copies categories for each group' do
    @builder.build_many(count: 2)

    ActivityGroup.last(2).each do |group|
      assert_equal 2, group.activity_group_categories.count
    end
  end

  # The link back to the template column is what tells "Tylko w tym arkuszu"
  # apart from a column that was copied.
  test 'build records which template category each column came from' do
    @builder.build(name: 'Lab 1')
    group = ActivityGroup.last!

    assert_equal @template.categories.order(:position).map(&:id),
                 group.activity_group_categories.map(&:source_category_id)
    assert_not group.activity_group_categories.first.sheet_only?
  end

  test 'a column added afterwards has no template category behind it' do
    group = @builder.build(name: 'Lab 1')
    added = group.activity_group_categories.create!(didactic_description: 'Extra', reward: 1, position: 2)

    assert_predicate added, :sheet_only?
  end

  # A run that failed halfway used to leave the sheets before it behind, with
  # no way to tell how far it got.
  test 'build_many rolls the whole run back when one sheet fails' do
    @template.categories.first.update_column(:didactic_description, nil)

    assert_no_difference('ActivityGroup.count') do
      assert_raises(ActiveRecord::RecordInvalid) { @builder.build_many(count: 3) }
    end
  end
end
