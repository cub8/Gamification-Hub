# frozen_string_literal: true

require 'test_helper'

class StudentsProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher)
    @current_user = FactoryBot.create(:user, role: :student)
    sign_in @current_user
    @story_group_student = FactoryBot.create(:story_group_student, user: @current_user, story_group: @story_group)
  end

  test 'should get index' do
    get story_group_student_profile_index_url(@story_group, @story_group_student)
    assert_response :success
  end
end
