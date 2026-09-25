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
    FactoryBot.create(
      :activity_group,
      story_group:             @story_group,
      activity_group_template: @template,
      name:                    'Lab 1',
    )
    FactoryBot.create(
      :activity_group,
      story_group:             @story_group,
      activity_group_template: @template,
      name:                    'Lab 2',
    )

    assert_equal 3, ActivityGroup.next_number_for_base(@template)
  end

  test 'next_number_for_base is scoped per template' do
    other_template = FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: 'Lab')
    FactoryBot.create(
      :activity_group,
      story_group:             @story_group,
      activity_group_template: other_template,
      name:                    'Lab 1',
    )
    FactoryBot.create(
      :activity_group,
      story_group:             @story_group,
      activity_group_template: other_template,
      name:                    'Lab 2',
    )

    assert_equal 1, ActivityGroup.next_number_for_base(@template)
  end

  test 'next_number_for_base ignores groups with non-numeric suffix' do
    FactoryBot.create(
      :activity_group,
      story_group:             @story_group,
      activity_group_template: @template,
      name:                    'Lab Advanced',
    )
    FactoryBot.create(
      :activity_group,
      story_group:             @story_group,
      activity_group_template: @template,
      name:                    'Lab',
    )

    assert_equal 3, ActivityGroup.next_number_for_base(@template)
  end

  test 'next_name_for_template returns base_name with next number' do
    FactoryBot.create(
      :activity_group,
      story_group:             @story_group,
      activity_group_template: @template,
      name:                    'Lab 1',
    )

    assert_equal 'Lab 2', ActivityGroup.next_name_for_template(@template)
  end

  test 'next_name_for_template returns base_name 1 for empty template' do
    assert_equal 'Lab 1', ActivityGroup.next_name_for_template(@template)
  end

  # The dialog's chip list and ActivityGroupBuilder#build_many read the same
  # call, so the names previewed are the names created.
  test 'next_names_for_template returns the run of names the next sheets will get' do
    FactoryBot.create(:activity_group, story_group: @story_group,
                                       activity_group_template: @template, name: 'Lab 1',)

    assert_equal ['Lab 2', 'Lab 3', 'Lab 4'], ActivityGroup.next_names_for_template(@template, 3)
  end

  test 'next_names_for_template returns one name for a count of one' do
    assert_equal ['Lab 1'], ActivityGroup.next_names_for_template(@template, 1)
  end

  # Soft delete (DECISIONS.md:54).
  test 'soft_delete! takes the sheet out of kept without destroying it' do
    sheet = FactoryBot.create(:activity_group, story_group: @story_group,
                                               activity_group_template: @template, name: 'Lab 1',)

    assert_difference('ActivityGroup.count', 0) { sheet.soft_delete! }
    assert_predicate sheet, :deleted?
    assert_empty ActivityGroup.kept.where(id: sheet.id)
    assert_includes ActivityGroup.deleted, sheet
  end
end
