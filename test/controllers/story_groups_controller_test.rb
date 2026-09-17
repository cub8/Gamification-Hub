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

    assert_turbo_redirected_to story_group_url(StoryGroup.last)
  end

  test 'should show story_group' do
    get story_group_url(@story_group)
    assert_response :success
  end

  test 'should get edit' do
    get edit_story_group_url(@story_group)
    assert_response :success
  end

  # An ordinary redirect, not a turbo-stream one: "Ustawienia grupy" is a page
  # now, so there is no frame to escape, and it lands back on itself.
  test 'should update story_group' do
    patch story_group_url(@story_group),
          params: {
            story_group: {
              currency_name: @story_group.currency_name,
              description:   @story_group.description,
              name:          @story_group.name,
            },
          }
    assert_redirected_to edit_story_group_url(@story_group)
  end

  test 'should get confirm_destroy' do
    get confirm_destroy_story_group_url(@story_group)
    assert_response :success
  end

  # The typed name is part of the request now — see StoryGroupsController#destroy.
  test 'should destroy story_group' do
    assert_difference('StoryGroup.count', -1) do
      delete story_group_url(@story_group), params: { confirm: @story_group.name }
    end

    assert_redirected_to story_groups_url
  end

  test 'should not destroy story_group without the typed name' do
    assert_no_difference('StoryGroup.count') do
      delete story_group_url(@story_group), params: { confirm: 'coś innego' }
    end

    assert_response :unprocessable_content
  end
end
