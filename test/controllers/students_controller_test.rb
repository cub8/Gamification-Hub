# frozen_string_literal: true

require 'test_helper'

class StudentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_user = FactoryBot.create(:user, role: :teacher)
    sign_in @current_user
    @story_group = FactoryBot.create(:story_group, owner: @current_user)
    @student1 = FactoryBot.create(:user, role: :student)
    @story_group_student = FactoryBot.create(:story_group_student, user: @student1, story_group: @story_group)
  end

  test 'should get index' do
    get story_group_students_url(@story_group)
    assert_response :success
  end

  test 'should get edit' do
    get edit_story_group_student_url(@story_group, @story_group_student)
    assert_response :success
  end

  test 'should get show' do
    get story_group_student_url(@story_group, @story_group_student)
    assert_response :success
  end

  test 'should update story_group_student' do
    patch story_group_student_url(@story_group, @story_group_student),
          params: {
            story_group_student: {
              lives: @story_group_student.lives + 1,
            },
          }

    assert_turbo_redirected_to story_group_student_url(@story_group, @story_group_student)
  end

  test 'should destroy story_group_student' do
    assert_difference('StoryGroupStudent.count', -1) do
      delete story_group_student_url(@story_group, @story_group_student)
    end

    # Submitted from the stacked confirmation dialog, so it answers with the
    # redirect stream that breaks out of the frame rather than a 302.
    assert_turbo_redirected_to story_group_students_url(@story_group)
  end
end
