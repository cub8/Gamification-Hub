# frozen_string_literal: true

require 'test_helper'

class DiscountCalculatorServiceTest < ActiveSupport::TestCase
  def setup
    @story_group = create(:story_group)
    @user = create(:user)

    @student = create(:story_group_student, story_group: @story_group, user: @user, total_currency: 10)

    create(:rank, story_group: @story_group, required_currency_value: 10, discount: 10)
    @random_badge = create(:badge, story_group: @story_group, discount: 5)
    create(:students_badge, story_group_student: @student, badge: @random_badge)

    @item = create(:item, story_group: @story_group)
  end
  # Item wymaga rangi i odznaki
  test 'requires both - applies when student has exactly the required rank' do
    req_rank = create(:rank, story_group: @story_group, required_currency_value: 100)
    req_badge = create(:badge, story_group: @story_group)
    @item.update!(min_rank_for_discount: req_rank)
    @item.discount_badges << req_badge

    @student.update!(total_currency: 100)

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 15, service.calculate.value
  end

  test 'requires both - applies when student has higher rank' do
    req_rank = create(:rank, story_group: @story_group, required_currency_value: 100)
    higher_rank = create(:rank, story_group: @story_group, required_currency_value: 200, discount: 15)
    req_badge = create(:badge, story_group: @story_group)
    @item.update!(min_rank_for_discount: req_rank)
    @item.discount_badges << req_badge
    @student.update!(total_currency: 200)

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 20, service.calculate.value
  end

  test 'requires both - applies when student has one of the required badges' do
    req_rank = create(:rank, story_group: @story_group, required_currency_value: 100)
    req_badge = create(:badge, story_group: @story_group, discount: 0)
    @item.update!(min_rank_for_discount: req_rank)
    @item.discount_badges << req_badge

    create(:students_badge, story_group_student: @student, badge: req_badge)

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 15, service.calculate.value
  end

  test 'requires both - applies when student has required rank AND badge' do
    req_rank = create(:rank, story_group: @story_group, required_currency_value: 100)
    req_badge = create(:badge, story_group: @story_group, discount: 0)
    @item.update!(min_rank_for_discount: req_rank)
    @item.discount_badges << req_badge

    @student.update!(total_currency: 100)
    create(:students_badge, story_group_student: @student, badge: req_badge)

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 15, service.calculate.value
  end

  test 'requires both - does NOT apply when student lacks required rank and badges' do
    req_rank = create(:rank, story_group: @story_group, required_currency_value: 100)
    req_badge = create(:badge, story_group: @story_group)
    @item.update!(min_rank_for_discount: req_rank)
    @item.discount_badges << req_badge

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 0, service.calculate.value
  end

  # Item wymaga tylko rangi
  test 'requires only rank - applies when student has exact rank' do
    req_rank = create(:rank, story_group: @story_group, required_currency_value: 100)
    @item.update!(min_rank_for_discount: req_rank)

    @student.update!(total_currency: 100)

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 15, service.calculate.value
  end

  test 'requires only rank - applies when student has higher rank' do
    req_rank = create(:rank, story_group: @story_group, required_currency_value: 100)
    higher_rank = create(:rank, story_group: @story_group, required_currency_value: 200, discount: 15)
    @item.update!(min_rank_for_discount: req_rank)

    @student.update!(total_currency: 200)

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 20, service.calculate.value
  end

  test 'requires only rank - does NOT apply when student lacks rank' do
    req_rank = create(:rank, story_group: @story_group, required_currency_value: 100)
    @item.update!(min_rank_for_discount: req_rank)

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 0, service.calculate.value
  end

  # Item wymaga tylko odznak
  test 'requires only badges - applies when student has one of the required badges' do
    req_badge1 = create(:badge, story_group: @story_group, discount: 0)
    req_badge2 = create(:badge, story_group: @story_group, discount: 0)
    @item.discount_badges << req_badge1
    @item.discount_badges << req_badge2

    create(:students_badge, story_group_student: @student, badge: req_badge1)

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 15, service.calculate.value
  end

  test 'requires only badges - does NOT apply when student has no required badges' do
    req_badge = create(:badge, story_group: @story_group)
    @item.discount_badges << req_badge

    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 0, service.calculate.value
  end

  # Item nie wymaga niczego
  test 'requires nothing - applies discount from any ranks and badges' do
    service = DiscountCalculatorService.new(student: @student, item: @item)
    assert_equal 15, service.calculate.value
  end
end
