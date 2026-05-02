# frozen_string_literal: true

require 'test_helper'

class JoinControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher)
    @invite = FactoryBot.create(:story_group_invite, story_group: @story_group)
  end

  test 'should join story_group' do
    @student = FactoryBot.create(:user, role: :student)
    sign_in @student

    assert_difference('StoryGroupStudent.count') do
      post join_index_url,
           params: {
             code: @invite.code,
           }
    end

    assert_redirected_to story_group_url(@story_group)
  end
end
