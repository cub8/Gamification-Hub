# frozen_string_literal: true

require 'test_helper'

class StudentsItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner_user = FactoryBot.create(:user)
    @teacher_user = FactoryBot.create(:user, role: :teacher)
    @student_user = FactoryBot.create(:user, role: :student)
    @other_student_user = FactoryBot.create(:user, role: :student)

    @story_group = FactoryBot.create(:story_group, owner_id: @owner_user.id)

    @student = FactoryBot.create(:story_group_student, story_group: @story_group, user: @student_user)
    @other_student = FactoryBot.create(:story_group_student, story_group: @story_group, user: @other_student_user)

    @item = FactoryBot.create(:item, story_group: @story_group)
    @students_item = FactoryBot.create(:students_item, story_group_student: @student, item: @item, price_paid: 20)
  end

  test 'owner can access student items index and show' do
    sign_in @owner_user

    get story_group_student_students_items_path(@story_group, @student)
    assert_response :success

    get story_group_student_students_item_path(@story_group, @student, @students_item)
    assert_response :success
  end

  test 'teacher can access student items index and show' do
    sign_in @teacher_user

    get story_group_student_students_items_path(@story_group, @student)
    assert_response :success

    get story_group_student_students_item_path(@story_group, @student, @students_item)
    assert_response :success
  end

  test 'the student themselves can access their items index and show' do
    sign_in @student_user

    get story_group_student_students_items_path(@story_group, @student)
    assert_response :success

    get story_group_student_students_item_path(@story_group, @student, @students_item)
    assert_response :success
  end

  test 'other student cannot access this student items index or show' do
    sign_in @other_student_user

    get story_group_student_students_items_path(@story_group, @student)
    assert_redirected_to root_path

    get story_group_student_students_item_path(@story_group, @student, @students_item)
    assert_redirected_to root_path
  end
end
