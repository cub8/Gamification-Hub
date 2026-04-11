# frozen_string_literal: true

require 'test_helper'

class StoryGroupStudentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_user = FactoryBot.create(:user, role: :teacher)
    sign_in @current_user
    @story_group = FactoryBot.create(:story_group, owner: @current_user)
    @student = FactoryBot.create(:user, role: :student)
    @story_group_student = FactoryBot.create(:story_group_student, user: @student, story_group: @story_group)
  end

  test 'should get index' do
    get story_group_story_group_students_url(@story_group)
    assert_response :success
  end
end
