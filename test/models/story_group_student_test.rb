# frozen_string_literal: true

require 'test_helper'

class StoryGroupStudentTest < ActiveSupport::TestCase

  setup do
    @owner = ::FactoryBot.create(:user)
    @student_user = ::FactoryBot.create(:user)
  end

  test 'sets default lives from story group on creation' do
    group = StoryGroup.create!(name: 'Test Group', currency_name: 'Gold', default_lives: 5, owner: @owner)

    student = StoryGroupStudent.create!(user: @student_user, story_group: group)

    assert_equal 5, student.lives, 'Student powinien otrzymać domyślną liczbę żyć z grupy'
  end

  test 'does not override provided lives on creation' do
    group = StoryGroup.create!(name: 'Another Group', currency_name: 'Silver', default_lives: 3, owner: @owner)

    student = StoryGroupStudent.create!(user: @student_user, story_group: group, lives: 10)

    assert_equal 10, student.lives, 'Callback nie powinien nadpisać ręcznie podanej liczby żyć'
  end

  test 'next_rank is the cheapest rank still out of reach' do
    group = FactoryBot.create(:story_group, owner: @owner)
    FactoryBot.create(:rank, story_group: group, name: 'Brąz',   required_currency_value: 10)
    gold = FactoryBot.create(:rank, story_group: group, name: 'Złoto',  required_currency_value: 100)
    FactoryBot.create(:rank, story_group: group, name: 'Platyna', required_currency_value: 500)

    student = FactoryBot.create(:story_group_student, user: @student_user, story_group: group,
                                                      total_currency: 40,)

    assert_equal gold, student.next_rank
  end

  test 'next_rank is nil at the top rank and with no ranks at all' do
    group = FactoryBot.create(:story_group, owner: @owner)
    student = FactoryBot.create(:story_group_student, user: @student_user, story_group: group,
                                                      total_currency: 40,)

    assert_nil student.next_rank, 'Grupa bez rang nie ma następnej rangi'

    FactoryBot.create(:rank, story_group: group, required_currency_value: 10)

    assert_nil student.reload.next_rank, 'Najwyższa ranga nie ma następnej'
  end

  test 'a rank exactly at the threshold counts as reached, not as next' do
    group = FactoryBot.create(:story_group, owner: @owner)
    gold = FactoryBot.create(:rank, story_group: group, name: 'Złoto', required_currency_value: 100)

    student = FactoryBot.create(:story_group_student, user: @student_user, story_group: group,
                                                      total_currency: 100,)

    assert_equal gold, student.rank
    assert_nil student.next_rank
  end
end
