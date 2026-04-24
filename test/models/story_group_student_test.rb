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
end
