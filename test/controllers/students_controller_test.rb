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

  test 'index offers a filter for each of rank, item and badge' do
    rank  = FactoryBot.create(:rank, story_group: @story_group, name: 'Nawigator', required_currency_value: 0)
    item  = FactoryBot.create(:item, story_group: @story_group, name: 'Kawa')
    badge = FactoryBot.create(:badge, story_group: @story_group, name: 'Zdobywca')

    get story_group_students_url(@story_group)

    assert_select "fieldset[data-list-search-key=\"rank\"] input[value=\"#{rank.id}\"]"
    assert_select "fieldset[data-list-search-key=\"item\"] input[value=\"#{item.id}\"]"
    assert_select "fieldset[data-list-search-key=\"badge\"] input[value=\"#{badge.id}\"]"
    assert_select 'fieldset input[checked]', 0
  end

  test 'index ticks the chips named in the URL and ignores the rest' do
    item = FactoryBot.create(:item, story_group: @story_group)
    FactoryBot.create(:item, story_group: @story_group)

    get story_group_students_url(@story_group, item: [item.id, '999999'])

    assert_select 'fieldset[data-list-search-key="item"] input[checked]', 1
    assert_select "fieldset[data-list-search-key=\"item\"] input[checked][value=\"#{item.id}\"]"
  end

  test 'index puts what each student holds on the row' do
    item  = FactoryBot.create(:item, story_group: @story_group)
    badge = FactoryBot.create(:badge, story_group: @story_group)
    FactoryBot.create(:students_item, story_group_student: @story_group_student, item: item)
    FactoryBot.create(:students_badge, story_group_student: @story_group_student, badge: badge)

    get story_group_students_url(@story_group)

    assert_select 'li[data-list-search-rank="none"]' \
                  "[data-list-search-item=\"#{item.id}\"][data-list-search-badge=\"#{badge.id}\"]"
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
