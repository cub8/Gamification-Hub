# frozen_string_literal: true

require 'test_helper'

class CurrencyAdjustmentFormTest < ActiveSupport::TestCase
  setup do
    @owner       = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @owner, currency_name: 'marchewki')
    @user        = FactoryBot.create(:user, role: :student)
    @student     = FactoryBot.create(:story_group_student, user: @user, story_group: @story_group,
                                                           current_currency: 20, total_currency: 40,)
  end

  def rank(name:, threshold:)
    FactoryBot.create(:rank, story_group: @story_group, name: name, required_currency_value: threshold)
  end

  def form(sign:, amount:)
    CurrencyAdjustmentForm.new(student: @student, sign: sign, amount: amount)
  end

  test 'defaults to Dodaj with nothing typed' do
    subject = CurrencyAdjustmentForm.for(@student)

    assert_predicate subject, :positive?
    assert_nil subject.value
    assert_not subject.validate
    assert_equal 'Podaj kwotę.', subject.error_for(:amount)
  end

  test 'refuses a zero and anything that is not a number' do
    assert_equal 'Podaj kwotę większą od zera.', form(sign: 1, amount: '0').tap(&:validate).error_for(:amount)
    assert_equal 'Podaj kwotę.', form(sign: 1, amount: 'dużo').tap(&:validate).error_for(:amount)
    assert_equal 'Podaj kwotę.', form(sign: -1, amount: '-5').tap(&:validate).error_for(:amount)
  end

  test 'refuses a correction that would take the balance below zero' do
    subject = form(sign: -1, amount: '21')

    assert_not subject.validate
    assert_equal 'Student ma tylko 20 do wydania.', subject.error_for(:amount)
  end

  test 'allows a correction that lands exactly on zero' do
    subject = form(sign: -1, amount: '20')

    assert subject.validate
    assert_equal 0, subject.new_balance
  end

  test 'a positive correction raises both columns' do
    subject = form(sign: 1, amount: '5')

    assert_equal 25, subject.new_balance
    assert_equal 45, subject.new_total
    assert_predicate subject, :total_changed?
  end

  test 'a negative correction moves only the spendable balance' do
    subject = form(sign: -1, amount: '5')

    assert_equal 15, subject.new_balance
    assert_equal 40, subject.new_total
    assert_not subject.total_changed?
  end

  test 'a rank can only move upward, and only when it actually crosses a rung' do
    rank(name: 'Rekrut', threshold: 0)
    rank(name: 'Kapitan', threshold: 50)

    assert_not form(sign: 1, amount: '5').rank_changed?

    crossing = form(sign: 1, amount: '10')
    assert_predicate crossing, :rank_changed?
    assert_equal 'Rekrut', crossing.current_rank.name
    assert_equal 'Kapitan', crossing.new_rank.name

    # Even a clawback big enough to matter leaves the rung alone, because it
    # never touches the total collected.
    assert_not form(sign: -1, amount: '20').rank_changed?
  end

  test 'saving writes one adjustment and moves the student' do
    subject = form(sign: -1, amount: '5')

    assert_difference('CurrencyTransaction.count', 1) do
      assert subject.save(granted_by_user: @owner)
    end

    entry = CurrencyTransaction.last
    assert_equal(-5, entry.amount)
    assert_equal 'adjustment', entry.kind
    assert_equal @owner, entry.granted_by_user

    @student.reload
    assert_equal 15, @student.current_currency
    assert_equal 40, @student.total_currency
  end

  test 'a refused form writes nothing' do
    subject = form(sign: -1, amount: '100')

    assert_no_difference('CurrencyTransaction.count') do
      assert_not subject.save(granted_by_user: @owner)
    end

    assert_equal 20, @student.reload.current_currency
  end

  test 'the service refuses an overdraw even when nothing validated it' do
    service = CurrencyAdjusterService.new(student: @student, granted_by_user: @owner)

    assert_no_difference('CurrencyTransaction.count') do
      assert_raises(CurrencyAdjusterService::Overdrawn) { service.adjust(-21) }
    end

    assert_equal 20, @student.reload.current_currency
  end
end
