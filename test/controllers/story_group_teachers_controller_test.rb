# frozen_string_literal: true

require 'test_helper'

class StoryGroupTeachersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_user = FactoryBot.create(:user, role: :teacher)
    sign_in @current_user
    @story_group = FactoryBot.create(:story_group, owner: @current_user)
    @teacher = FactoryBot.create(:user, role: :teacher)
    @story_group_teacher = FactoryBot.create(:story_group_teacher, user: @teacher, story_group: @story_group)
  end

  test 'should get index' do
    get story_group_story_group_teachers_url(@story_group)
    assert_response :success
  end
end
