# frozen_string_literal: true

require 'test_helper'

class ActivityGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher)
    @template = FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: 'Lab')
    FactoryBot.create(:activity_group_template_category,
                      activity_group_template: @template,
                      didactic_description:    'Task 1',
                      reward:                  10,
                      position:                0,)
    @activity_group = FactoryBot.create(:activity_group,
                                        story_group:             @story_group,
                                        activity_group_template: @template,
                                        name:                    'Lab 1',)
    sign_in @teacher
  end

  test 'should get index' do
    get story_group_activity_groups_url(@story_group)
    assert_response :success
  end

  test 'should get edit' do
    get edit_story_group_activity_group_url(@story_group, @activity_group)
    assert_response :success
  end

  test 'should create activity group with auto-generated name' do
    assert_difference('ActivityGroup.count', 1) do
      post story_group_activity_groups_url(@story_group),
           params: { activity_group: { activity_group_template_id: @template.id } }
    end

    assert_equal 'Lab 2', ActivityGroup.last!.name
    assert_redirected_to story_group_activity_groups_url(@story_group)
  end

  test 'should create activity group with provided name' do
    assert_difference('ActivityGroup.count', 1) do
      post story_group_activity_groups_url(@story_group),
           params: { activity_group: { activity_group_template_id: @template.id, name: 'Custom Name' } }
    end

    assert_equal 'Custom Name', ActivityGroup.last!.name
  end

  test 'should copy categories from template on create' do
    post story_group_activity_groups_url(@story_group),
         params: { activity_group: { activity_group_template_id: @template.id } }
    group = ActivityGroup.last!

    assert_equal @template.categories.count, group.activity_group_categories.count
    assert_equal 'Task 1', group.activity_group_categories.first.didactic_description
    assert_equal 10, group.activity_group_categories.first.reward
  end

  test 'should update activity group' do
    patch story_group_activity_group_url(@story_group, @activity_group),
          params: { activity_group: { name: 'Updated Lab' } }

    assert_equal 'Updated Lab', @activity_group.reload.name
    assert_redirected_to story_group_activity_groups_url(@story_group)
  end

  test 'should destroy activity group' do
    assert_difference('ActivityGroup.count', -1) do
      delete story_group_activity_group_url(@story_group, @activity_group)
    end

    assert_redirected_to story_group_activity_groups_url(@story_group)
  end

  test 'should create multiple groups via create_bulk' do
    assert_difference('ActivityGroup.count', 3) do
      post create_bulk_story_group_activity_groups_url(@story_group),
           params: { template_id: @template.id, count: 3 }
    end

    assert_redirected_to story_group_activity_groups_url(@story_group)
  end

  test 'should not access groups for story group not managed by teacher' do
    other_story_group = FactoryBot.create(:story_group)
    get story_group_activity_groups_url(other_story_group)
    assert_redirected_to root_url
  end

  test 'should not create group without authentication' do
    sign_out
    assert_no_difference('ActivityGroup.count') do
      post story_group_activity_groups_url(@story_group),
           params: { activity_group: { activity_group_template_id: @template.id } }
    end
  end
end
