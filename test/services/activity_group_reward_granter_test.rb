# frozen_string_literal: true

require 'test_helper'

class ActivityGroupRewardGranterTest < ActiveSupport::TestCase
  setup do
    @story_group    = FactoryBot.create(:story_group)
    @activity_group = FactoryBot.create(:activity_group, story_group: @story_group)
    @category       = FactoryBot.create(:activity_group_category, activity_group: @activity_group, reward: 10)
    user            = FactoryBot.create(:user, :student)
    @student        = FactoryBot.create(:story_group_student,
                                        user:             user,
                                        story_group:      @story_group,
                                        current_currency: 0,
                                        total_currency:   0,)
    @granter = ActivityGroupRewardGranter.new(activity_group: @activity_group, story_group: @story_group)
  end

  test 'save creates StudentsActivityGroupCategory for new pairs' do
    assert_difference('StudentsActivityGroupCategory.count', 1) do
      @granter.save(Set[[@category.id, @student.id]])
    end
  end

  test 'save creates CurrencyTransaction for new pairs' do
    assert_difference('CurrencyTransaction.count', 1) do
      @granter.save(Set[[@category.id, @student.id]])
    end

    transaction = CurrencyTransaction.last!
    assert_equal @student, transaction.student
    assert_equal @category, transaction.transactionable
    assert_equal 10, transaction.amount
    assert_equal 'reward', transaction.kind
  end

  test 'save increments student currency' do
    @granter.save(Set[[@category.id, @student.id]])

    @student.reload
    assert_equal 10, @student.current_currency
    assert_equal 10, @student.total_currency
  end

  test 'save does not grant reward twice for already completed pair' do
    StudentsActivityGroupCategory.create!(activity_group_category_id: @category.id, student_id: @student.id)

    granter = ActivityGroupRewardGranter.new(activity_group: @activity_group, story_group: @story_group)
    assert_no_difference('CurrencyTransaction.count') do
      granter.save(Set[[@category.id, @student.id]])
    end
  end

  test 'save ignores pairs with unknown category' do
    assert_no_difference('CurrencyTransaction.count') do
      @granter.save(Set[[0, @student.id]])
    end
  end

  test 'save ignores pairs with unknown student' do
    assert_no_difference('CurrencyTransaction.count') do
      @granter.save(Set[[@category.id, 0]])
    end
  end
end
