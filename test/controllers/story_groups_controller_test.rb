# frozen_string_literal: true

require 'test_helper'

class StoryGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_user = FactoryBot.create(:user, role: :teacher)
    sign_in @current_user
    @story_group = FactoryBot.create(:story_group, owner: @current_user)
  end

  test 'should get index' do
    get story_groups_url
    assert_response :success
  end

  test 'should get new' do
    get new_story_group_url
    assert_response :success
  end

  test 'should create story_group' do
    assert_difference('StoryGroup.count') do
      post story_groups_url,
           params: {
             story_group: {
               currency_name: @story_group.currency_name,
               description:   @story_group.description,
               name:          @story_group.name,
             },
           }
    end

    assert_redirected_to story_group_url(StoryGroup.last)
  end

  test 'should show story_group' do
    get story_group_url(@story_group)
    assert_response :success
  end

  test 'should get edit' do
    get edit_story_group_url(@story_group)
    assert_response :success
  end

  test 'should update story_group' do
    patch story_group_url(@story_group),
          params: {
            story_group: {
              currency_name: @story_group.currency_name,
              description:   @story_group.description,
              name:          @story_group.name,
            },
          }
    assert_redirected_to story_group_url(@story_group)
  end

  test 'should destroy story_group' do
    assert_difference('StoryGroup.count', -1) do
      delete story_group_url(@story_group)
    end

    assert_redirected_to story_groups_url
  end
end
