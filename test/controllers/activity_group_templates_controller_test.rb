# frozen_string_literal: true

require 'test_helper'

class ActivityGroupTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher)
    @template = FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: 'Lab')
    sign_in @teacher
  end

  test 'should get index' do
    get story_group_activity_group_templates_url(@story_group)
    assert_response :success
  end

  test 'should get new' do
    get new_story_group_activity_group_template_url(@story_group)
    assert_response :success
  end

  test 'should get edit' do
    get edit_story_group_activity_group_template_url(@story_group, @template)
    assert_response :success
  end

  test 'should create activity_group_template' do
    assert_difference('ActivityGroupTemplate.count') do
      post story_group_activity_group_templates_url(@story_group),
           params: {
             activity_group_template: {
               base_name:             'Homework',
               categories_attributes: [
                 { didactic_description: 'Task 1', reward: 10, position: 0 },
               ],
             },
           }
    end
    assert_redirected_to story_group_activity_groups_url(@story_group)
  end

  test 'should update activity_group_template' do
    patch story_group_activity_group_template_url(@story_group, @template),
          params: {
            activity_group_template: {
              base_name: 'Updated Lab',
            },
          }
    assert_redirected_to story_group_activity_groups_url(@story_group)
    assert_equal 'Updated Lab', @template.reload.base_name
  end

  test 'should destroy activity_group_template' do
    assert_difference('ActivityGroupTemplate.count', -1) do
      delete story_group_activity_group_template_url(@story_group, @template)
    end
    assert_redirected_to story_group_activity_groups_url(@story_group)
  end

  test 'should not access templates for story group not managed by teacher' do
    other_story_group = FactoryBot.create(:story_group)
    get story_group_activity_group_templates_url(other_story_group)
    assert_redirected_to root_url
  end

  test 'should not create template without authentication' do
    sign_out
    assert_no_difference('ActivityGroupTemplate.count') do
      post story_group_activity_group_templates_url(@story_group),
           params: { activity_group_template: { base_name: 'Lab' } }
    end
  end
end
