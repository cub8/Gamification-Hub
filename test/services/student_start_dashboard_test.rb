# frozen_string_literal: true

require 'test_helper'

class StudentStartDashboardTest < ActiveSupport::TestCase
  setup do
    @student = FactoryBot.create(:user, role: :student)
  end

  test 'summarises every membership, ordered by group name' do
    %w[Gamma Alfa Beta].each do |name|
      group = FactoryBot.create(:story_group, name: name)
      FactoryBot.create(:story_group_student, user: @student, story_group: group)
    end

    dashboard = StudentStartDashboard.new(user: @student).load

    assert_equal(%w[Alfa Beta Gamma], dashboard.groups.map { |group| group.story_group.name })
  end

  test 'counts badges per group without leaking another groups badges' do
    mine = FactoryBot.create(:story_group, name: 'Moja')
    other = FactoryBot.create(:story_group, name: 'Obca')
    FactoryBot.create_list(:badge, 4, story_group: mine)
    FactoryBot.create_list(:badge, 9, story_group: other)
    membership = FactoryBot.create(:story_group_student, user: @student, story_group: mine)
    FactoryBot.create(:students_badge, story_group_student: membership, badge: mine.badges.first)

    group = StudentStartDashboard.new(user: @student).load.groups.sole

    assert_equal 1, group.badges_earned
    assert_equal 4, group.badges_total
  end

  test 'a membership with nothing collected yet is fresh' do
    group = FactoryBot.create(:story_group)
    membership = FactoryBot.create(:story_group_student, user: @student, story_group: group,
                                                         current_currency: 0, total_currency: 0,)

    assert_predicate StudentStartDashboard.new(user: @student).load.groups.sole, :fresh?

    membership.update!(total_currency: 1)

    assert_not_predicate StudentStartDashboard.new(user: @student).load.groups.sole, :fresh?
  end

  test 'a student who spent everything is not fresh — lifetime total is what counts' do
    group = FactoryBot.create(:story_group)
    FactoryBot.create(:story_group_student, user: @student, story_group: group,
                                            current_currency: 0, total_currency: 50,)

    assert_not_predicate StudentStartDashboard.new(user: @student).load.groups.sole, :fresh?
  end

  test 'the feed merges groups, sorts newest first and stops at the limit' do
    first = FactoryBot.create(:story_group)
    second = FactoryBot.create(:story_group)
    in_first = FactoryBot.create(:story_group_student, user: @student, story_group: first)
    in_second = FactoryBot.create(:story_group_student, user: @student, story_group: second)

    (StudentStartDashboard::FEED_LIMIT + 3).times do |index|
      CurrencyTransaction.create!(student: index.even? ? in_first : in_second,
                                  amount: index, kind: :reward, created_at: index.minutes.ago,)
    end

    feed = StudentStartDashboard.new(user: @student).load.feed

    assert_equal StudentStartDashboard::FEED_LIMIT, feed.size
    assert_equal feed.map(&:created_at).sort.reverse, feed.map(&:created_at)
    assert_equal [0, 1, 2, 3, 4, 5, 6, 7], feed.map(&:amount)
  end

  test 'the feed never shows another student in the same group' do
    group = FactoryBot.create(:story_group)
    mine = FactoryBot.create(:story_group_student, user: @student, story_group: group)
    theirs = FactoryBot.create(:story_group_student, story_group: group,
                                                     user:        FactoryBot.create(:user, role: :student),)

    CurrencyTransaction.create!(student: mine, amount: 5, kind: :reward)
    CurrencyTransaction.create!(student: theirs, amount: 99, kind: :reward)

    feed = StudentStartDashboard.new(user: @student).load.feed

    assert_equal [5], feed.map(&:amount)
  end

  test 'a student in no groups loads empty rather than raising' do
    dashboard = StudentStartDashboard.new(user: @student).load

    assert_empty dashboard.groups
    assert_empty dashboard.feed
  end
end
