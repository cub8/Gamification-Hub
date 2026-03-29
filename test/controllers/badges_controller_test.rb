# frozen_string_literal: true

require 'test_helper'

class BadgesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher)
    sign_in @teacher
  end

  test 'should create badge' do
    assert_difference('Badge.count') do
      post story_group_badges_url(@story_group),
           params: {
             badge: {
               name: 'Achievement',
               description: 'An achievement badge',
             },
           }
    end

    assert_redirected_to story_group_url(@story_group)
  end

  test 'should not create badge for story group not owned by teacher' do
    other_teacher = FactoryBot.create(:user, role: :teacher)
    other_story_group = FactoryBot.create(:story_group, owner: other_teacher)

    post story_group_badges_url(other_story_group),
         params: {
           badge: {
             name: 'Achievement',
             description: 'An achievement badge',
           },
         }

    assert_redirected_to root_url
  end

  test 'should destroy badge' do
    badge = FactoryBot.create(:badge, story_group: @story_group)

    assert_difference('Badge.count', -1) do
      delete story_group_badge_url(@story_group, badge)
    end

    assert_redirected_to story_group_url(@story_group)
  end

  test 'should not create badge without authentication' do
    sign_out
    assert_no_difference('Badge.count') do
      post story_group_badges_url(@story_group),
           params: {
             badge: {
               name: 'Achievement',
               description: 'An achievement badge',
             },
           }
    end
  end
end