# frozen_string_literal: true

require 'test_helper'

class TeachersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_user = FactoryBot.create(:user, role: :teacher)
    sign_in @current_user
    @story_group = FactoryBot.create(:story_group, owner: @current_user)
    @teacher1 = FactoryBot.create(:user, role: :teacher)
    @teacher2 = FactoryBot.create(:user, role: :teacher)
    @story_group_teacher = FactoryBot.create(:story_group_teacher, user: @teacher1, story_group: @story_group)
  end

  test 'should get index' do
    get story_group_teachers_url(@story_group)
    assert_response :success
  end

  test 'should get new' do
    get new_story_group_teacher_url(@story_group)
    assert_response :success
  end

  test 'should create story_group_teacher' do
    assert_difference('StoryGroupTeacher.count') do
      post story_group_teachers_url(@story_group),
           params: {
             story_group_teacher: {
               user_id: @teacher2.id,
             },
           }
    end

    assert_redirected_to story_group_teachers_url(@story_group)
  end

  test 'should destroy story_group_teacher' do
    assert_difference('StoryGroupTeacher.count', -1) do
      delete story_group_teacher_url(@story_group, @story_group_teacher)
    end

    assert_redirected_to story_group_teachers_url(@story_group)
  end

end
