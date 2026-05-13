# frozen_string_literal: true

require 'test_helper'

class ItemPurchaseServiceTest < ActiveSupport::TestCase
  setup do
    @story_group = FactoryBot.create(:story_group)
    @user = FactoryBot.create(:user)

    @student = FactoryBot.create(:story_group_student,
                                 story_group:      @story_group,
                                 user:             @user,
                                 current_currency: 100,
                                 lives:            1,)

    @item = FactoryBot.create(:item, story_group: @story_group, price: 50)
  end

  test 'successful purchase - deducts currency and creates records' do
    assert_equal 100, @student.current_currency
    assert_empty @student.students_items

    service = ItemPurchaseService.new(student: @student, item: @item)

    diff = {
      -> { @student.reload.current_currency }     => -50,
      -> { @student.students_items.count }        => 1,
      -> { @student.currency_transactions.count } => 1,
    }

    assert_difference diff do
      result = service.call
      assert result.success?, result.errors.join(', ')
    end

    assert_equal 50, @student.students_items.last.price_paid
    assert_equal 0, @student.students_items.last.discount_applied
  end

  test 'failed purchase - not enough currency' do
    @student.update!(current_currency: 10)
    assert_operator @student.current_currency, :<, @item.price

    service = ItemPurchaseService.new(student: @student, item: @item)

    assert_no_difference ['@student.current_currency', 'StudentsItem.count', 'CurrencyTransaction.count'] do
      result = service.call
      refute result.success?
      assert_includes result.errors, 'Masz za mało waluty, aby kupić ten przedmiot.'
    end
  end

  test 'failed purchase - eligibility requirements not met' do
    @student.update!(lives: 0)
    assert_equal 0, @student.lives
    assert_not @item.can_buy_at_0_lives

    service = ItemPurchaseService.new(student: @student, item: @item)

    assert_no_difference ['StudentsItem.count', 'CurrencyTransaction.count'] do
      result = service.call
      refute result.success?
      assert_includes result.errors, 'Wymagane jest posiadanie przynajmniej jednego życia.'
    end
  end

  test 'purchase with discount - deducts correct amount' do
    FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 0, discount: 20)

    assert_equal 40, @item.discounted_price_for(@student)

    service = ItemPurchaseService.new(student: @student, item: @item)

    assert_difference -> { @student.reload.current_currency } => -40 do
      result = service.call
      assert result.success?, result.errors.join(', ')
    end

    assert_equal 20, @student.students_items.last.discount_applied
  end
end
