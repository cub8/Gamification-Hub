# frozen_string_literal: true

require 'test_helper'

class StoryGroupMembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @story_group = create(:story_group)
    @membership = create(:story_group_student, story_group: @story_group)
    sign_in @membership.user
  end

  test 'leaving redirects to the group list' do
    delete story_group_membership_path(@story_group)

    assert_redirected_to story_groups_path
    assert_not StoryGroupStudent.exists?(@membership.id)
  end

  test 'leaving from the dialog redirects the whole page, not the dialog frame' do
    delete story_group_membership_path(@story_group), headers: { 'Turbo-Frame' => 'modal' }

    assert_turbo_redirected_to story_groups_path
    assert_not StoryGroupStudent.exists?(@membership.id)
  end
end
