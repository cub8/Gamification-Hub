# frozen_string_literal: true

require 'test_helper'

class PurchaseEligibilityServiceTest < ActiveSupport::TestCase
  setup do
    @story_group = FactoryBot.create(:story_group)
    @user = FactoryBot.create(:user)

    @student = FactoryBot.create(:story_group_student, story_group: @story_group, user: @user, lives: 1,
total_currency: 10,)

    @item = FactoryBot.create(:item, story_group: @story_group, can_buy_at_0_lives: false)
  end

  test 'eligible when student has lives and item has no requirements' do
    assert_operator @student.lives, :>, 0
    assert_empty @item.unlock_badges
    assert_nil @item.unlock_rank

    result = PurchaseEligibilityService.new(student: @student, item: @item).call

    assert result.eligible?
    assert_empty result.errors
  end

  test 'NOT eligible when student has 0 lives and item does not allow buying at 0 lives' do
    @student.update!(lives: 0)

    assert_equal 0, @student.lives
    assert_equal false, @item.can_buy_at_0_lives

    result = PurchaseEligibilityService.new(student: @student, item: @item).call

    refute result.eligible?
    assert_includes result.errors, 'Wymagane jest posiadanie przynajmniej jednego życia.'
  end

  test 'eligible when student has 0 lives BUT item allows buying at 0 lives' do
    @student.update!(lives: 0)
    @item.update!(can_buy_at_0_lives: true)

    assert_equal 0, @student.lives
    assert_equal true, @item.can_buy_at_0_lives

    result = PurchaseEligibilityService.new(student: @student, item: @item).call

    assert result.eligible?
    assert_empty result.errors
  end

  test 'NOT eligible when student lacks required rank' do
    req_rank = FactoryBot.create(:rank, story_group: @story_group, name: 'Ekspert', required_currency_value: 100)
    @item.update!(unlock_rank: req_rank)

    assert_operator @student.total_currency, :<, req_rank.required_currency_value

    result = PurchaseEligibilityService.new(student: @student, item: @item).call

    refute result.eligible?
    assert_includes result.errors, 'Wymagana ranga: Ekspert.'
  end

  test 'eligible when student has required rank' do
    req_rank = FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 100)
    @item.update!(unlock_rank: req_rank)
    @student.update!(total_currency: 100)

    assert_equal req_rank, @student.rank

    result = PurchaseEligibilityService.new(student: @student, item: @item).call

    assert result.eligible?
    assert_empty result.errors
  end

  test 'NOT eligible when student lacks required badges' do
    req_badge1 = FactoryBot.create(:badge, story_group: @story_group, name: 'Wojownik')
    req_badge2 = FactoryBot.create(:badge, story_group: @story_group, name: 'Mag')
    @item.unlock_badges << req_badge1
    @item.unlock_badges << req_badge2

    assert_empty @student.badges & @item.unlock_badges

    result = PurchaseEligibilityService.new(student: @student, item: @item).call

    refute result.eligible?
    assert_includes result.errors, 'Brakujące odznaki: Wojownik, Mag.'
  end

  test 'eligible when student has all required badges' do
    req_badge = FactoryBot.create(:badge, story_group: @story_group)
    @item.unlock_badges << req_badge
    FactoryBot.create(:students_badge, story_group_student: @student, badge: req_badge)

    assert_equal @item.unlock_badges.to_a, (@student.badges & @item.unlock_badges).to_a

    result = PurchaseEligibilityService.new(student: @student, item: @item).call

    assert result.eligible?
    assert_empty result.errors
  end

  test 'accumulates multiple errors when multiple requirements are not met' do
    @student.update!(lives: 0)

    req_rank = FactoryBot.create(:rank, story_group: @story_group, name: 'Mistrz', required_currency_value: 100)
    @item.update!(unlock_rank: req_rank)

    req_badge = FactoryBot.create(:badge, story_group: @story_group, name: 'Tarcza')
    @item.unlock_badges << req_badge

    result = PurchaseEligibilityService.new(student: @student, item: @item).call

    refute result.eligible?
    assert_equal 3, result.errors.count
    assert_includes result.errors, 'Wymagane jest posiadanie przynajmniej jednego życia.'
    assert_includes result.errors, 'Wymagana ranga: Mistrz.'
    assert_includes result.errors, 'Brakujące odznaki: Tarcza.'
  end
end
