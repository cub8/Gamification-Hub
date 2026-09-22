# frozen_string_literal: true

require 'test_helper'

class TeacherListTest < ActiveSupport::TestCase
  setup do
    @owner       = FactoryBot.create(:user, role: :teacher, full_name: 'Zofia Zawadzka')
    @story_group = FactoryBot.create(:story_group, owner: @owner)
  end

  def supporting(name)
    user = FactoryBot.create(:user, role: :teacher, full_name: name)

    FactoryBot.create(:story_group_teacher, user: user, story_group: @story_group)
  end

  def list = TeacherList.new(story_group: @story_group)

  test 'the owner leads the list whatever their name sorts as' do
    supporting('Adam Adamczyk')

    assert_equal(['Zofia Zawadzka', 'Adam Adamczyk'], list.rows.map { |row| row.person.full_name })
  end

  test 'the owner row carries no membership and cannot be removed' do
    owner_row = list.rows.first

    assert owner_row.owner?
    assert_not owner_row.removable?
    assert_nil owner_row.membership
    assert_equal @story_group.created_at, owner_row.added_at
  end

  test 'a supporting teacher carries their membership and the date they joined' do
    membership = supporting('Adam Adamczyk')
    row = list.rows.last

    assert_not row.owner?
    assert row.removable?
    assert_equal membership, row.membership
    assert_equal membership.created_at, row.added_at
  end

  # A byte comparator puts "Łukasz" after "Zofia", which reads as a bug.
  test 'supporting teachers sort by folded name' do
    supporting('Łukasz Lis')
    supporting('Marta Mazur')
    supporting('Adam Adamczyk')

    assert_equal(['Adam Adamczyk', 'Łukasz Lis', 'Marta Mazur'],
                 list.rows.drop(1).map { |row| row.person.full_name },)
  end

  test 'a group with no supporting teachers is still a list of one' do
    assert_equal 1, list.size
    assert list.any?
  end

  # The controller hands in the policy-scoped relation rather than the raw one.
  test 'it lists the memberships it is given' do
    supporting('Adam Adamczyk')
    scoped = TeacherList.new(story_group: @story_group,
                             memberships: StoryGroupTeacher.none,)

    assert_equal [@owner], scoped.rows.map(&:person)
  end
end
