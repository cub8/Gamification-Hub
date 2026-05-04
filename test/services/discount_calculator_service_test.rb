# frozen_string_literal: true

require 'test_helper'

class DiscountCalculatorServiceTest < ActiveSupport::TestCase
  setup do
    @story_group = FactoryBot.create(:story_group)
    @user = FactoryBot.create(:user)

    @student = FactoryBot.create(:story_group_student, story_group: @story_group, user: @user, total_currency: 10)

    FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 10, discount: 10)
    @random_badge = FactoryBot.create(:badge, story_group: @story_group, discount: 5)
    FactoryBot.create(:students_badge, story_group_student: @student, badge: @random_badge)

    @item = FactoryBot.create(:item, story_group: @story_group)
  end

  test 'requires both rank and badges - applies when student has exactly the required rank' do
    req_rank = FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 100, discount: 10)
    req_badge = FactoryBot.create(:badge, story_group: @story_group, discount: 5)
    @item.update!(min_rank_for_discount: req_rank)
    @item.discount_badges << req_badge

    @student.update!(total_currency: 100)

    assert_equal req_rank, @student.rank
    assert_empty @student.badges & @item.discount_badges

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 15, service.calculate.value
  end

  test 'requires both rank and badges - applies when student has higher rank' do
    req_rank = FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 100, discount: 10)
    higher_rank = FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 200, discount: 15)
    req_badge = FactoryBot.create(:badge, story_group: @story_group)
    @item.update!(min_rank_for_discount: req_rank)
    @item.discount_badges << req_badge
    @student.update!(total_currency: 200)

    assert_equal higher_rank, @student.rank
    assert_operator @student.rank.required_currency_value, :>, req_rank.required_currency_value
    assert_empty @student.badges & @item.discount_badges

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 20, service.calculate.value
  end

  test 'requires both rank and badges - applies when student has one of the required badges' do
    req_rank = FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 100, discount: 10)
    req_badge = FactoryBot.create(:badge, story_group: @story_group, discount: 0)
    @item.update!(min_rank_for_discount: req_rank)
    @item.discount_badges << req_badge

    FactoryBot.create(:students_badge, story_group_student: @student, badge: req_badge)

    assert_operator @student.total_currency, :<, req_rank.required_currency_value
    assert_includes @student.badges, req_badge

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 15, service.calculate.value
  end

  test 'requires both rank and badges - applies when student has required rank AND badge' do
    req_rank = FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 100, discount: 10)
    req_badge = FactoryBot.create(:badge, story_group: @story_group, discount: 0)
    @item.update!(min_rank_for_discount: req_rank)
    @item.discount_badges << req_badge

    @student.update!(total_currency: 100)
    FactoryBot.create(:students_badge, story_group_student: @student, badge: req_badge)

    assert_equal req_rank, @student.rank
    assert_includes @student.badges, req_badge

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 15, service.calculate.value
  end

  test 'requires both rank and badges - does NOT apply when student lacks required rank and badges' do
    req_rank = FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 100, discount: 10)
    req_badge = FactoryBot.create(:badge, story_group: @story_group)
    @item.update!(min_rank_for_discount: req_rank)
    @item.discount_badges << req_badge

    assert_operator @student.total_currency, :<, req_rank.required_currency_value
    assert_empty @student.badges & @item.discount_badges

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 0, service.calculate.value
  end

  test 'requires only rank - applies when student has exact rank' do
    req_rank = FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 100, discount: 10)
    @item.update!(min_rank_for_discount: req_rank)

    @student.update!(total_currency: 100)
    assert_equal req_rank, @student.rank

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 15, service.calculate.value
  end

  test 'requires only rank - applies when student has higher rank' do
    req_rank = FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 100, discount: 10)
    higher_rank = FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 200, discount: 15)
    @item.update!(min_rank_for_discount: req_rank)

    @student.update!(total_currency: 200)

    assert_equal higher_rank, @student.rank
    assert_operator @student.rank.required_currency_value, :>, req_rank.required_currency_value

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 20, service.calculate.value
  end

  test 'requires only rank - does NOT apply when student lacks rank' do
    req_rank = FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 100, discount: 10)
    @item.update!(min_rank_for_discount: req_rank)

    assert_operator @student.total_currency, :<, req_rank.required_currency_value

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 0, service.calculate.value
  end

  test 'requires only badges - applies when student has one of the required badges' do
    req_badge1 = FactoryBot.create(:badge, story_group: @story_group, discount: 0)
    req_badge2 = FactoryBot.create(:badge, story_group: @story_group, discount: 0)
    @item.discount_badges << req_badge1
    @item.discount_badges << req_badge2

    FactoryBot.create(:students_badge, story_group_student: @student, badge: req_badge1)

    assert_includes @student.badges, req_badge1
    refute_includes @student.badges, req_badge2

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 15, service.calculate.value
  end

  test 'requires only badges - does NOT apply when student has no required badges' do
    req_badge = FactoryBot.create(:badge, story_group: @story_group)
    @item.discount_badges << req_badge

    assert_empty @student.badges & @item.discount_badges

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 0, service.calculate.value
  end

  test 'requires nothing - applies discount from any ranks and badges' do
    service = DiscountCalculatorService.new(student: @student, item: @item)

    assert_nil @item.min_rank_for_discount
    assert_empty @item.discount_badges

    assert_equal 15, service.calculate.value
  end
end
