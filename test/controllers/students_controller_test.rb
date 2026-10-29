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

    assert_turbo_redirected_to story_group_students_url(@story_group)
  end

  test 'should get new_import' do
    get new_import_story_group_students_url(@story_group)
    assert_response :success
  end

  test 'import adds a student found by email and shows the results page' do
    other_student = FactoryBot.create(:user, role: :student, email: 'jan@example.com')

    assert_difference('StoryGroupStudent.count', 1) do
      post import_story_group_students_url(@story_group),
           params: { file: fixture_file_upload('students_import.csv', 'text/csv') }
    end

    assert_response :success
    assert_equal other_student, @story_group.student_memberships.last.user
  end

  test 'import redirects back with an alert when no file was selected' do
    post import_story_group_students_url(@story_group)

    assert_redirected_to new_import_story_group_students_url(@story_group)
    assert_equal 'Wybierz plik CSV.', flash[:alert]
  end

  test 'import redirects back with an alert for an unparseable file' do
    post import_story_group_students_url(@story_group),
         params: { file: fixture_file_upload('malformed_import.csv', 'text/csv') }

    assert_redirected_to new_import_story_group_students_url(@story_group)
    assert_match(/nie udało się odczytać/i, flash[:alert])
  end

  test 'lives notice uses Polish plural forms' do
    @story_group_student.update!(lives: 1)

    post update_lives_story_group_student_url(@story_group, @story_group_student, change: 1)
    assert_equal "#{@story_group_student.display_name} ma teraz 2 życia.", flash[:notice]

    @story_group_student.update!(lives: 4)
    post update_lives_story_group_student_url(@story_group, @story_group_student, change: 1)
    assert_equal "#{@story_group_student.display_name} ma teraz 5 żyć.", flash[:notice]
  end

  test 'lives notice in English' do
    patch locale_path, params: { locale: 'en' }
    @story_group_student.update!(lives: 0)

    post update_lives_story_group_student_url(@story_group, @story_group_student, change: 1)
    assert_equal "#{@story_group_student.display_name} now has 1 life.", flash[:notice]
  end
end
