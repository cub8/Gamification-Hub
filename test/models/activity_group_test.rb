# frozen_string_literal: true

require 'test_helper'

class ActivityGroupTest < ActiveSupport::TestCase
  setup do
    @story_group = FactoryBot.create(:story_group)
    @template = FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: 'Lab')
  end

  test 'next_number_for_base returns 1 when no groups exist' do
    assert_equal 1, ActivityGroup.next_number_for_base(@template)
  end

  test 'next_number_for_base increments from last matching group' do
    FactoryBot.create(:activity_group, story_group: @story_group, activity_group_template: @template, name: 'Lab 1')
    FactoryBot.create(:activity_group, story_group: @story_group, activity_group_template: @template, name: 'Lab 2')
    assert_equal 3, ActivityGroup.next_number_for_base(@template)
  end

  test 'next_number_for_base is scoped per template' do
    other_template = FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: 'Lab')
    FactoryBot.create(:activity_group, story_group: @story_group, activity_group_template: other_template,
name: 'Lab 1',)
    FactoryBot.create(:activity_group, story_group: @story_group, activity_group_template: other_template,
name: 'Lab 2',)
    assert_equal 1, ActivityGroup.next_number_for_base(@template)
  end

  test 'next_number_for_base ignores groups with non-numeric suffix' do
    FactoryBot.create(:activity_group, story_group: @story_group, activity_group_template: @template,
name: 'Lab Advanced',)
    FactoryBot.create(:activity_group, story_group: @story_group, activity_group_template: @template, name: 'Lab')
    assert_equal 3, ActivityGroup.next_number_for_base(@template)
  end

  test 'next_name_for_template returns base_name with next number' do
    FactoryBot.create(:activity_group, story_group: @story_group, activity_group_template: @template, name: 'Lab 1')
    assert_equal 'Lab 2', ActivityGroup.next_name_for_template(@template)
  end

  test 'next_name_for_template returns base_name 1 for empty template' do
    assert_equal 'Lab 1', ActivityGroup.next_name_for_template(@template)
  end
end
