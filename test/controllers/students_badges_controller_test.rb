# frozen_string_literal: true

require 'test_helper'

class StudentsBadgesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_user = FactoryBot.create(:user, role: :teacher)
    sign_in @current_user
    @story_group = FactoryBot.create(:story_group, owner: @current_user)
    @student = FactoryBot.create(:user, role: :student)
    @story_group_student = FactoryBot.create(:story_group_student, user: @student, story_group: @story_group)
    @badge1 = FactoryBot.create(:badge, story_group: @story_group)
    @badge2 = FactoryBot.create(:badge, story_group: @story_group)
    @students_badge = FactoryBot.create(:students_badge, story_group_student: @story_group_student, badge: @badge1)
  end

  test 'should get new' do
    get new_story_group_student_badge_url(@story_group, @story_group_student)
    assert_response :success
  end

  test 'should create students_badge' do
    assert_difference('StudentsBadge.count') do
      post story_group_student_badges_url(@story_group, @story_group_student),
           params: {
             students_badge: {
               badge_id: @badge2.id,
             },
           }
    end

    assert_redirected_to story_group_student_url(@story_group, @story_group_student)
  end

  test 'should destroy students_badge' do
    assert_difference('StudentsBadge.count', -1) do
      delete story_group_student_badge_url(@story_group, @story_group_student, @students_badge)
    end

    assert_redirected_to story_group_student_url(@story_group, @story_group_student)
  end
end
