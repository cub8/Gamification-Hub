# frozen_string_literal: true

require 'test_helper'

class CurrencyLedgerTest < ActiveSupport::TestCase
  setup do
    @owner       = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @owner, currency_name: 'marchewki')
    @user        = FactoryBot.create(:user, role: :student)
    @student     = FactoryBot.create(:story_group_student, user: @user, story_group: @story_group,
                                                           current_currency: 0, total_currency: 0,)
  end

  # Written oldest first, each moving current_currency the way its own writer
  # does, so the balance the ledger walks back from is the real one.
  def reward(amount, category: nil, at: Time.current)
    entry = FactoryBot.create(:currency_transaction, student: @student, amount: amount,
                                                     kind: :reward, transactionable: category,
                                                     created_at: at,)
    @student.increment!(:current_currency, amount)
    @student.increment!(:total_currency, amount)
    entry
  end

  def purchase(price, item:, at: Time.current)
    entry = FactoryBot.create(:currency_transaction, student: @student, amount: -price,
                                                     kind: :purchase, transactionable: item,
                                                     created_at: at,)
    @student.increment!(:current_currency, -price)
    entry
  end

  def correction(amount, by: @owner, at: Time.current)
    entry = FactoryBot.create(:currency_transaction, student: @student, amount: amount,
                                                     kind: :adjustment, granted_by_user: by,
                                                     created_at: at,)
    @student.increment!(:current_currency, amount)
    @student.increment!(:total_currency, amount) if amount.positive?
    entry
  end

  def ledger = CurrencyLedger.new(student: @student.reload)

  test 'is empty for a student who has never been awarded anything' do
    assert_not ledger.any?
    assert_equal 0, ledger.size
    assert_empty ledger.entries
  end

  test 'reads newest first' do
    reward(10, at: 3.days.ago)
    reward(20, at: 1.day.ago)

    assert_equal [20, 10], ledger.entries.map(&:amount)
  end

  test 'the running balance walks back to where the student started' do
    item = FactoryBot.create(:item, story_group: @story_group, name: 'Poprawa', price: 15)

    reward(30, at: 4.days.ago)
    purchase(15, item: item, at: 3.days.ago)
    reward(20, at: 2.days.ago)
    correction(-5, at: 1.day.ago)

    entries = ledger.entries

    # Newest row leaves the balance the student has now, and every row below it
    # explains the step above.
    assert_equal 30, @student.reload.current_currency
    assert_equal [30, 35, 15, 30], entries.map(&:balance_after)

    # The oldest row minus its own amount is where they came from: zero.
    assert_equal 0, entries.last.balance_after - entries.last.amount
  end

  test 'a filter does not change any row balance' do
    item = FactoryBot.create(:item, story_group: @story_group, name: 'Poprawa', price: 15)

    reward(30, at: 3.days.ago)
    purchase(15, item: item, at: 2.days.ago)
    reward(20, at: 1.day.ago)

    unfiltered = ledger.entries.to_h { |entry| [entry.id, entry.balance_after] }
    rewards    = ledger.entries(kind: 'reward')

    assert_equal 2, rewards.size
    rewards.each { |entry| assert_equal unfiltered[entry.id], entry.balance_after }
  end

  test 'counts each kind and the whole list' do
    item = FactoryBot.create(:item, story_group: @story_group, name: 'Poprawa', price: 5)

    reward(30, at: 3.days.ago)
    purchase(5, item: item, at: 2.days.ago)
    correction(-5, at: 1.day.ago)

    assert_equal 3, ledger.count_for(nil)
    assert_equal 1, ledger.count_for('reward')
    assert_equal 1, ledger.count_for('purchase')
    assert_equal 1, ledger.count_for('adjustment')
  end

  test 'names a reward after its column and the sheet it belongs to' do
    sheet    = FactoryBot.create(:activity_group, story_group: @story_group, name: 'Laboratoria 4')
    category = FactoryBot.create(:activity_group_category, activity_group:       sheet,
                                                           didactic_description: 'Obecność',)
    reward(10, category: category)

    entry = ledger.entries.first

    assert_equal 'Obecność', entry.title
    assert_equal 'Laboratoria 4', entry.context
    assert_equal 'Nagroda', entry.label
    assert_equal 'earn', entry.tone
  end

  test 'names a purchase after the item and a correction after the teacher' do
    item = FactoryBot.create(:item, story_group: @story_group, name: 'Poprawa wejściówki', price: 5)

    reward(30, at: 3.days.ago)
    purchase(5, item: item, at: 2.days.ago)
    correction(-5, at: 1.day.ago)

    corrected, bought, = ledger.entries

    assert_equal 'Korekta waluty', corrected.title
    assert_equal @owner.full_name, corrected.context
    assert_equal 'Korekta', corrected.label

    assert_equal 'Poprawa wejściówki', bought.title
    assert_nil bought.context
    assert_equal 'Zakup', bought.label
    assert_equal 'spend', bought.tone
  end

  test 'keeps a purchase of a withdrawn item and flags it' do
    item = FactoryBot.create(:item, story_group: @story_group, name: 'Poprawa', price: 5)
    reward(30, at: 2.days.ago)
    purchase(5, item: item, at: 1.day.ago)
    item.soft_delete!

    entry = ledger.entries.first

    assert_equal 'Poprawa', entry.title
    assert_predicate entry, :withdrawn?
  end

  test 'signs amounts with a real minus' do
    item = FactoryBot.create(:item, story_group: @story_group, name: 'Poprawa', price: 5)
    reward(30, at: 2.days.ago)
    purchase(5, item: item, at: 1.day.ago)

    assert_equal ['−5', '+30'], ledger.entries.map(&:signed_amount)
  end

  test 'loads the whole ledger without a query per row' do
    sheet    = FactoryBot.create(:activity_group, story_group: @story_group, name: 'Laboratoria 1')
    category = FactoryBot.create(:activity_group_category, activity_group: sheet)
    item     = FactoryBot.create(:item, story_group: @story_group, name: 'Poprawa', price: 1)

    6.times { |i| reward(10, category: category, at: (20 - i).days.ago) }
    6.times { |i| purchase(1, item: item, at: (10 - i).days.ago) }

    subject = ledger
    queries = count_queries { subject.entries.each { |entry| [entry.title, entry.context] } }

    assert_operator queries, :<=, 4, "expected a fixed number of queries, ran #{queries}"
  end

  def count_queries(&)
    count = 0
    counter = ->(_name, _start, _finish, _id, payload) { count += 1 unless payload[:name] == 'SCHEMA' }

    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
    count
  end
end
