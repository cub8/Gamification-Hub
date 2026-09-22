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

    assert_turbo_redirected_to story_group_teachers_url(@story_group)
  end

  test 'should get confirm_destroy' do
    get confirm_destroy_story_group_teacher_url(@story_group, @story_group_teacher)
    assert_response :success
  end

  # Submitted from inside the confirmation dialog, so it breaks out of the
  # frame the same way create does.
  test 'should destroy story_group_teacher' do
    assert_difference('StoryGroupTeacher.count', -1) do
      delete story_group_teacher_url(@story_group, @story_group_teacher)
    end

    assert_turbo_redirected_to story_group_teachers_url(@story_group)
  end

  test 'adding somebody already in the group is refused on the field' do
    assert_no_difference('StoryGroupTeacher.count') do
      post story_group_teachers_url(@story_group),
           params: { story_group_teacher: { user_id: @teacher1.id } }
    end

    assert_response :unprocessable_content
    assert_select '.gh-err span', 'Ta osoba jest już w grupie.'
  end

  test 'the pool holds teachers of this university only' do
    elsewhere = FactoryBot.create(:user, role: :teacher, university_name: 'Somewhere else')

    get new_story_group_teacher_url(@story_group)

    assert_select '.gh-tr button[value=?]', @teacher2.id.to_s, count: 1
    assert_select '.gh-tr button[value=?]', elsewhere.id.to_s, count: 0
  end

  test 'a global admin sees every university in the pool' do
    elsewhere = FactoryBot.create(:user, role: :teacher, university_name: 'Somewhere else')
    admin = FactoryBot.create(:user, role: :global_admin)
    sign_out
    sign_in admin

    get new_story_group_teacher_url(@story_group)

    assert_select '.gh-tr button[value=?]', elsewhere.id.to_s, count: 1
  end

  test 'a supporting teacher may read the list but not change it' do
    sign_out
    sign_in @teacher1

    get story_group_teachers_url(@story_group)
    assert_response :success

    post story_group_teachers_url(@story_group),
         params: { story_group_teacher: { user_id: @teacher2.id } }
    assert_redirected_to root_path

    assert_no_difference('StoryGroupTeacher.count') do
      delete story_group_teacher_url(@story_group, @story_group_teacher)
    end
    assert_redirected_to root_path
  end

  # The owner has no membership row, so there is nothing to destroy — and no
  # point offering them in the dialog either.
  test 'the owner is listed but never removable, and is not in the pool' do
    get story_group_teachers_url(@story_group)
    assert_select 'a[href=?]',
                  confirm_destroy_story_group_teacher_path(@story_group, @story_group_teacher), count: 1
    assert_select '.gh-trow', 3 # header + owner + one supporting teacher

    get new_story_group_teacher_url(@story_group)
    assert_select '.gh-tr button[value=?]', @current_user.id.to_s, count: 0
  end
end
