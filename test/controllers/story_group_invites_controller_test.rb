# frozen_string_literal: true

require 'test_helper'

class StoryGroupInvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_user = FactoryBot.create(:user, role: :teacher)
    sign_in @current_user
    @story_group = FactoryBot.create(:story_group, owner: @current_user)
    @invite = FactoryBot.create(:story_group_invite, story_group: @story_group)
  end

  test 'should get index' do
    get story_group_invites_url(@story_group)
    assert_response :success
  end

  test 'should get new' do
    get new_story_group_invite_url(@story_group)
    assert_response :success
  end

  test 'should create invite' do
    assert_difference('StoryGroupInvite.count') do
      post story_group_invites_url(@story_group),
           params: {
             story_group_invite: {
               max_uses:   10,
               expires_at: 24.hours.from_now,
             },
           }
    end

    assert_redirected_to story_group_invites_url(@story_group)
  end

  test 'should get edit' do
    get edit_story_group_invite_url(@story_group, @invite)
    assert_response :success
  end

  test 'should update invite' do
    patch story_group_invite_url(@story_group, @invite),
          params: {
            story_group_invite: {
              max_uses:   @invite.max_uses + 1,
              expires_at: 24.hours.from_now,
            },
          }

    assert_redirected_to story_group_invites_url(@story_group)
  end

  test 'should get show' do
    get story_group_invite_url(@story_group, @invite)
    assert_response :success
  end

  test 'should destroy invite' do
    assert_difference('StoryGroupInvite.count', -1) do
      delete story_group_invite_url(@story_group, @invite)
    end

    assert_redirected_to story_group_invites_url(@story_group)
  end
end
