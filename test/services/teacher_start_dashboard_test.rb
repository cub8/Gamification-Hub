# frozen_string_literal: true

require 'test_helper'

class TeacherStartDashboardTest < ActiveSupport::TestCase
  setup do
    @teacher = FactoryBot.create(:user, role: :teacher)
  end

  test 'covers owned and supported groups, but nothing the teacher only learns in' do
    owned = FactoryBot.create(:story_group, owner: @teacher, name: 'Alfa')
    supported = FactoryBot.create(:story_group, name: 'Beta')
    FactoryBot.create(:story_group_teacher, user: @teacher, story_group: supported)
    learning = FactoryBot.create(:story_group, name: 'Gamma')
    FactoryBot.create(:story_group_student, user: @teacher, story_group: learning)

    groups = TeacherStartDashboard.new(user: @teacher).load.groups

    assert_equal(%w[Alfa Beta], groups.map { |group| group.story_group.name })
    assert_equal %w[Prowadzisz Wspierasz], groups.map(&:role)
    assert_equal([owned.id, supported.id], groups.map { |group| group.story_group.id })
  end

  test 'buckets purchases by day and counts only today and yesterday as recent' do
    membership = membership_in(FactoryBot.create(:story_group, owner: @teacher))

    purchase(membership, amount: 1, at: 1.hour.ago)
    purchase(membership, amount: 2, at: 1.day.ago)
    purchase(membership, amount: 3, at: 9.days.ago)

    dashboard = TeacherStartDashboard.new(user: @teacher).load

    assert_equal 1, dashboard.purchases_on('Dziś').size
    assert_equal 1, dashboard.purchases_on('Wczoraj').size
    assert_equal 1, dashboard.purchases_on('Wcześniej').size
    assert_equal 2, dashboard.recent_purchases.size
    assert_equal 1, dashboard.recent_group_count
  end

  test 'only purchases reach the list — rewards and adjustments do not' do
    membership = membership_in(FactoryBot.create(:story_group, owner: @teacher))

    purchase(membership, amount: 5)
    CurrencyTransaction.create!(student: membership, amount: 10, kind: :reward)
    CurrencyTransaction.create!(student: membership, amount: -2, kind: :adjustment)

    dashboard = TeacherStartDashboard.new(user: @teacher).load

    assert_equal 1, dashboard.purchases.size
    assert_equal 5, dashboard.purchases.sole.price
  end

  test 'price is the absolute value — a purchase is stored as a negative amount' do
    membership = membership_in(FactoryBot.create(:story_group, owner: @teacher))
    purchase(membership, amount: 12)

    assert_equal 12, TeacherStartDashboard.new(user: @teacher).load.purchases.sole.price
  end

  test 'the filter narrows the list but not the greeting' do
    first = FactoryBot.create(:story_group, owner: @teacher, name: 'Alfa')
    second = FactoryBot.create(:story_group, owner: @teacher, name: 'Beta')
    purchase(membership_in(first), amount: 1)
    purchase(membership_in(second), amount: 2)

    dashboard = TeacherStartDashboard.new(user: @teacher, filter: second.id).load

    assert_equal [2], dashboard.purchases.map(&:price)
    assert_equal 2, dashboard.recent_purchases.size, 'Powitanie opisuje wszystkie grupy, nie filtr'
    assert_equal second.id, dashboard.filter
  end

  test 'a blank filter param means all groups' do
    group = FactoryBot.create(:story_group, owner: @teacher)
    purchase(membership_in(group), amount: 1)

    assert_nil TeacherStartDashboard.new(user: @teacher, filter: '').load.filter
    assert_equal 1, TeacherStartDashboard.new(user: @teacher, filter: '').load.purchases.size
  end

  test 'a group never sees another group purchases' do
    mine = FactoryBot.create(:story_group, owner: @teacher)
    theirs = FactoryBot.create(:story_group)
    purchase(membership_in(mine), amount: 1)
    purchase(membership_in(theirs), amount: 99)

    assert_equal [1], TeacherStartDashboard.new(user: @teacher).load.purchases.map(&:price)
  end

  test 'new purchase counts are per group and only count the recent window' do
    first = FactoryBot.create(:story_group, owner: @teacher, name: 'Alfa')
    second = FactoryBot.create(:story_group, owner: @teacher, name: 'Beta')
    in_first = membership_in(first)
    purchase(in_first, amount: 1)
    purchase(in_first, amount: 2, at: 1.day.ago)
    purchase(membership_in(second), amount: 3, at: 8.days.ago)

    groups = TeacherStartDashboard.new(user: @teacher).load.groups

    assert_equal [2, 0], groups.map(&:new_purchases)
    assert_equal [1, 1], groups.map(&:students_count)
  end

  # --- "Czeka na ocenę" -----------------------------------------------------

  test 'pending is the newest sheet with a category nobody has been awarded in' do
    group = FactoryBot.create(:story_group, owner: @teacher)
    membership = membership_in(group)

    older = FactoryBot.create(:activity_group, story_group: group, name: 'Stary', created_at: 3.days.ago)
    FactoryBot.create(:activity_group_category, activity_group: older)

    newer = FactoryBot.create(:activity_group, story_group: group, name: 'Nowy', created_at: 1.hour.ago)
    awarded = FactoryBot.create(:activity_group_category, activity_group: newer, position: 0)
    FactoryBot.create_list(:activity_group_category, 2, activity_group: newer, position: 1)
    StudentsActivityGroupCategory.create!(student: membership, activity_group_category: awarded)

    pending = TeacherStartDashboard.new(user: @teacher).load.pending

    assert_equal newer, pending.activity_group
    assert_equal 2, pending.categories_count, 'Liczy tylko kategorie bez żadnej przyznanej nagrody'
    assert_equal 1, pending.students_count
  end

  test 'a sheet where every category has at least one award is not pending' do
    group = FactoryBot.create(:story_group, owner: @teacher)
    membership = membership_in(group)
    activity_group = FactoryBot.create(:activity_group, story_group: group)

    FactoryBot.create_list(:activity_group_category, 2, activity_group: activity_group).each do |category|
      StudentsActivityGroupCategory.create!(student: membership, activity_group_category: category)
    end

    assert_nil TeacherStartDashboard.new(user: @teacher).load.pending
  end

  test 'a sheet in someone else group is never pending here' do
    FactoryBot.create(:story_group, owner: @teacher)
    other = FactoryBot.create(:story_group)
    FactoryBot.create(:activity_group_category,
                      activity_group: FactoryBot.create(:activity_group, story_group: other),)

    assert_nil TeacherStartDashboard.new(user: @teacher).load.pending
  end

  test 'a teacher with no groups loads empty rather than raising' do
    dashboard = TeacherStartDashboard.new(user: @teacher).load

    assert_empty dashboard.groups
    assert_empty dashboard.purchases
    assert_nil dashboard.pending
  end

  private

  def membership_in(story_group)
    FactoryBot.create(:story_group_student, story_group: story_group,
                                            user:        FactoryBot.create(:user, role: :student),)
  end

  def purchase(membership, amount:, at: Time.current)
    CurrencyTransaction.create!(
      student:         membership,
      amount:          -amount,
      kind:            :purchase,
      transactionable: FactoryBot.create(:item, story_group: membership.story_group),
      created_at:      at,
    )
  end
end
