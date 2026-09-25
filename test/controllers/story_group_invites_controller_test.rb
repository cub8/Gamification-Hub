# frozen_string_literal: true

require 'test_helper'

class StoryGroupInvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_user = FactoryBot.create(:user, role: :teacher)
    sign_in @current_user
    @story_group = FactoryBot.create(:story_group, owner: @current_user)
    @invite = FactoryBot.create(:story_group_invite, story_group: @story_group)
  end

  # The form posts switches and a split date/time, not the columns themselves —
  # InviteForm is what turns them back into max_uses and expires_at.
  def form_params(limit: true, max_uses: 10, expiry: true, on: Time.zone.tomorrow, at: '23:59')
    {
      story_group_invite: {
        limit_enabled:  limit ? '1' : '0',
        max_uses:       max_uses,
        expiry_enabled: expiry ? '1' : '0',
        expires_on:     on.to_fs(:iso8601),
        expires_time:   at,
      },
    }
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
      post story_group_invites_url(@story_group), params: form_params
    end

    assert_turbo_redirected_to story_group_invites_url(@story_group)
  end

  test 'should get edit' do
    get edit_story_group_invite_url(@story_group, @invite)
    assert_response :success
  end

  test 'should update invite' do
    patch story_group_invite_url(@story_group, @invite),
          params: form_params(max_uses: @invite.max_uses + 1)

    assert_turbo_redirected_to story_group_invites_url(@story_group)
  end

  test 'should get show' do
    get story_group_invite_url(@story_group, @invite)
    assert_response :success
  end

  test 'should get quick' do
    get quick_story_group_invites_url(@story_group)
    assert_response :success
  end

  test 'should get the delete confirmation' do
    get confirm_destroy_story_group_invite_url(@story_group, @invite)

    assert_response :success
  end

  # Submitted from inside the dialog, so it breaks out of the frame with the
  # turbo_stream redirect action rather than a plain 302.
  test 'should destroy invite' do
    assert_difference('StoryGroupInvite.count', -1) do
      delete story_group_invite_url(@story_group, @invite)
    end

    assert_turbo_redirected_to story_group_invites_url(@story_group)
  end
end
