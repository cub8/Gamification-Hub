# frozen_string_literal: true

require 'test_helper'

# The student's own money screens — Historia waluty (#/s/history,
# js-expanded/30-sp.js:29-33) and Moje przedmioty (#/s/my-items, :19-20) — and
# the teacher's correction dialog behind them (mAdjust, 30-student.js:49-55).
class CurrencySmokeTest < ActionDispatch::IntegrationTest
  MODAL = { 'Turbo-Frame' => 'modal' }.freeze

  setup do
    @owner = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @owner, name: 'Kosmiczne króliki',
                                                   currency_name: 'marchewki',)
    @user = FactoryBot.create(:user, role: :student, full_name: 'Anna Kowalska')
    @student = FactoryBot.create(:story_group_student, user: @user, story_group: @story_group,
                                                       lives: 3, current_currency: 30,
                                                       total_currency: 50,)
    sign_in @user
  end

  # sign_in is a no-op while a session is live — the magic-link verify refuses
  # to run for someone already logged in — so switching user needs the sign_out.
  def sign_in_as(user)
    sign_out
    sign_in user
  end

  def item(name:, price: 20, **attributes)
    FactoryBot.create(:item, story_group: @story_group, name: name, price: price, **attributes)
  end

  def rank(name:, threshold:)
    FactoryBot.create(:rank, story_group: @story_group, name: name, required_currency_value: threshold)
  end

  def bought(name:, price: 20, paid: nil, discount: 0, at: Time.current)
    FactoryBot.create(:students_item, story_group_student: @student, item: item(name: name, price: price),
                                      price_paid: paid || price, discount_applied: discount,
                                      created_at: at,)
  end

  def entry(amount:, kind:, at: Time.current, **attributes)
    FactoryBot.create(:currency_transaction, student: @student, amount: amount, kind: kind,
                                             created_at: at, **attributes,)
  end

  def visit_history(**query)
    get story_group_student_currency_transactions_path(@story_group, @student, **query)
  end

  def visit_inventory
    get story_group_student_students_items_path(@story_group, @student)
  end

  def rows = css_select('.gh-ledger-row:not(.gh-ledger-row--header)')

  # Trimmed text of every match, so assertions read as data rather than nodes.
  def texts(selector) = css_select(selector).map { |node| node.text.strip }

  def balances = texts('.gh-ledger-balance')

  # ---- Historia waluty -------------------------------------------------

  test 'the history reads both numbers in its lead' do
    entry(amount: 50, kind: :reward)

    visit_history

    assert_response :success
    assert_select 'h1.gh-h1', 'Historia waluty'
    assert_select '.gh-lead', 'Masz 30 do wydania i 50 zebrane łącznie.'
  end

  test 'the ledger names every column and every kind' do
    sheet    = FactoryBot.create(:activity_group, story_group: @story_group, name: 'Laboratoria 4')
    category = FactoryBot.create(:activity_group_category, activity_group:       sheet,
                                                           didactic_description: 'Obecność',)

    entry(amount: 50, kind: :reward, transactionable: category, at: 3.days.ago)
    entry(amount: -15, kind: :purchase, transactionable: item(name: 'Poprawa wejściówki'), at: 2.days.ago)
    entry(amount: -5, kind: :adjustment, granted_by_user: @owner, at: 1.day.ago)

    visit_history

    assert_equal ['Kwota', 'Typ', 'Za co', 'Kiedy', 'Saldo po'], texts('.gh-ledger-row--header [role=columnheader]')
    assert_equal %w[Korekta Zakup Nagroda], texts('.gh-ledger-type-pill')
    assert_equal ['−5', '−15', '+50'], texts('.gh-ledger-amount')
    assert_select '.gh-ledger-source', /Obecność/
    assert_select '.gh-ledger-source small', 'Laboratoria 4'
    assert_select '.gh-ledger-source small', @owner.full_name
  end

  test 'the running balance walks back from what the student has now' do
    entry(amount: 50, kind: :reward, at: 3.days.ago)
    entry(amount: -15, kind: :purchase, transactionable: item(name: 'Poprawa'), at: 2.days.ago)
    entry(amount: -5, kind: :adjustment, granted_by_user: @owner, at: 1.day.ago)

    visit_history

    assert_equal %w[30 35 50], balances
  end

  test 'filtering narrows the rows without moving any balance' do
    entry(amount: 50, kind: :reward, at: 2.days.ago)
    entry(amount: -20, kind: :purchase, transactionable: item(name: 'Poprawa'), at: 1.day.ago)

    visit_history
    assert_equal 2, rows.size
    all = balances

    visit_history(kind: 'reward')
    assert_equal 1, rows.size
    assert_select '.gh-purchase-filter-chip[aria-current=true]', /Nagrody/
    assert_equal [all.last], balances
  end

  test 'an empty filter says so, an empty ledger says something else' do
    entry(amount: 50, kind: :reward)

    visit_history(kind: 'purchase')
    assert_select '.gh-explainer-note', 'Nie masz jeszcze wpisów tego typu.'

    CurrencyTransaction.destroy_all
    visit_history
    assert_select '.gh-empty-state .gh-h2', 'Pierwsze wpisy pojawią się po zajęciach'
    assert_select '.gh-ledger-row', false
  end

  test 'a purchase of a withdrawn item stays in the ledger, tagged' do
    gone = item(name: 'Stary przedmiot')
    entry(amount: -10, kind: :purchase, transactionable: gone)
    gone.soft_delete!

    visit_history

    assert_select '.gh-ledger-source', /Stary przedmiot/
    assert_select '.gh-ledger-source .gh-tag--removed', 'Usunięty z oferty'
  end

  test 'the filter chips count what is behind them' do
    entry(amount: 50, kind: :reward, at: 2.days.ago)
    entry(amount: -20, kind: :purchase, transactionable: item(name: 'Poprawa'), at: 1.day.ago)

    visit_history

    assert_equal %w[2 1 1 0], texts('.gh-purchase-filter-chip .gh-count-label')
  end

  test 'a teacher reads the same ledger, a stranger reads none of it' do
    entry(amount: 50, kind: :reward)

    sign_in_as @owner
    visit_history
    assert_response :success
    assert_select '.gh-ledger-row .gh-ledger-amount', '+50'

    stranger = FactoryBot.create(:user, role: :student)
    FactoryBot.create(:story_group_student, user: stranger, story_group: @story_group)
    sign_in_as stranger
    visit_history
    assert_redirected_to root_path
  end

  # ---- Moje przedmioty -------------------------------------------------

  test 'the inventory counts what is owned and sends you back to the shop' do
    bought(name: 'Poprawa wejściówki', price: 20, paid: 15)
    bought(name: 'Konsultacja', price: 10)

    visit_inventory

    assert_response :success
    assert_select 'h1.gh-h1', 'Moje przedmioty'
    assert_select '.gh-lead', /\A2 przedmioty\. Wykorzystanie przedmiotu zgłaszasz/
    assert_select '.gh-inventory-grid .gh-card-name', 2
    assert_select ".gh-button-row a[href='#{story_group_shop_index_path(@story_group)}']", 'Przejdź do sklepu'
  end

  test 'an owned card says when and for how much, without a price chip' do
    bought(name: 'Poprawa wejściówki', price: 20, paid: 15, discount: 25)

    visit_inventory

    assert_select '.gh-card-footer .gh-card-meta', /\AKupione .*, za 15\z/
    assert_select '.gh-inventory-grid .gh-price-badge', false
  end

  test 'a withdrawn item stays owned and says why it is nowhere else' do
    gone = bought(name: 'Stary przedmiot')
    gone.item.soft_delete!

    visit_inventory

    assert_select '.gh-card--consumed .gh-card-name', 'Stary przedmiot'
    assert_select '.gh-tag--removed', 'Usunięty z oferty'
  end

  test 'the grid closes with what the shop can still sell you' do
    # Owning one does not take it off the shelf — a student may buy the same
    # thing twice — so the count is everything they can afford today.
    bought(name: 'Poprawa wejściówki')
    item(name: 'Droga rzecz', price: 500)

    visit_inventory

    assert_select '.gh-empty-slot-panel p', 'Stać cię teraz na 1 przedmiot w sklepie.'
    assert_select ".gh-empty-slot-panel a[href='#{story_group_shop_index_path(@story_group)}']", 'Zobacz sklep'
  end

  test 'an empty inventory points at the shop' do
    visit_inventory

    assert_select '.gh-empty-state .gh-h2', 'Nie masz jeszcze żadnego przedmiotu'
    assert_select '.gh-inventory-grid', false
    assert_select '.gh-empty-state a', 'Przejdź do sklepu'
  end

  test 'a teacher following the URL gets the teacher wording and no shop slot' do
    bought(name: 'Poprawa wejściówki', price: 20, paid: 15)
    sign_in_as @owner

    visit_inventory

    assert_select 'h1.gh-h1', 'Przedmioty — Anna Kowalska'
    assert_select '.gh-empty-slot-panel', false
    assert_select '.gh-price-badge b', '15'
  end

  # ---- Koryguj walutę --------------------------------------------------

  test 'the correction dialog opens on Dodaj with no preview yet' do
    sign_in_as @owner

    get new_story_group_student_currency_adjustment_path(@story_group, @student), headers: MODAL

    assert_response :success
    assert_select 'turbo-frame#modal'
    assert_select '.gh-h2', 'Koryguj walutę'
    assert_select 'p', 'Anna Kowalska ma teraz 30 do wydania.'
    assert_select '.gh-segmented-toggle-3 input[value="1"][checked]'
    assert_select '[data-currency-adjust-target=preview][hidden]'
    assert_select '[data-currency-adjust-target=error][hidden]'
    assert_select '[data-currency-adjust-target=submit]', 'Podaj kwotę'
    # No reason field: a correction stores none.
    assert_select 'input[name=?]', 'currency_adjustment[reason]', false
  end

  test 'the dialog hands the browser the ladder it needs to preview a rank' do
    rank(name: 'Rekrut', threshold: 0)
    rank(name: 'Kapitan', threshold: 100)
    sign_in_as @owner

    get new_story_group_student_currency_adjustment_path(@story_group, @student), headers: MODAL

    form = css_select('form').first
    assert_equal 30, form['data-currency-adjust-balance-value'].to_i
    assert_equal 50, form['data-currency-adjust-total-value'].to_i
    assert_equal [{ 'v' => 0, 'n' => 'Rekrut' }, { 'v' => 100, 'n' => 'Kapitan' }],
                 JSON.parse(form['data-currency-adjust-rungs-value'])
    assert_equal 'Student ma tylko 30 do wydania.', form['data-currency-adjust-over-value']
  end

  test 'adding raises both columns and lands on the history tab' do
    sign_in_as @owner

    assert_difference('CurrencyTransaction.count', 1) do
      post story_group_student_currency_adjustment_path(@story_group, @student),
           params: { currency_adjustment: { sign: '1', amount: '20' } }
    end

    assert_turbo_redirected_to story_group_student_path(@story_group, @student, tab: 'hist')

    @student.reload
    assert_equal 50, @student.current_currency
    assert_equal 70, @student.total_currency

    get story_group_student_path(@story_group, @student, tab: 'hist')
    assert_select '#gh-toasts template[data-toast-target=seed]', 'Dodano 20. Saldo: 50.'
  end

  test 'subtracting moves only the spendable balance' do
    sign_in_as @owner

    post story_group_student_currency_adjustment_path(@story_group, @student),
         params: { currency_adjustment: { sign: '-1', amount: '10' } }

    @student.reload
    assert_equal 20, @student.current_currency
    assert_equal 50, @student.total_currency
  end

  test 'an overdraw is refused on the field, and nothing is written' do
    sign_in_as @owner

    assert_no_difference('CurrencyTransaction.count') do
      post story_group_student_currency_adjustment_path(@story_group, @student),
           params: { currency_adjustment: { sign: '-1', amount: '31' } }
    end

    assert_response :unprocessable_content
    assert_select '.gh-text-input--invalid input[aria-invalid=true]'
    assert_select '.gh-field-error[role=alert] span', 'Student ma tylko 30 do wydania.'
    # The toggle comes back the way the teacher left it.
    assert_select '.gh-segmented-toggle-3 input[value="-1"][checked]'
    assert_equal 30, @student.reload.current_currency
  end

  test 'a blank amount is refused too' do
    sign_in_as @owner

    assert_no_difference('CurrencyTransaction.count') do
      post story_group_student_currency_adjustment_path(@story_group, @student),
           params: { currency_adjustment: { sign: '1', amount: '' } }
    end

    assert_response :unprocessable_content
    assert_select '.gh-field-error[role=alert] span', 'Podaj kwotę.'
  end

  test 'the server renders the preview itself, so the dialog works without JS' do
    rank(name: 'Rekrut', threshold: 0)
    rank(name: 'Kapitan', threshold: 60)
    sign_in_as @owner

    # A refused submission is the only render that carries a typed amount, so
    # push one that fails on a different field than the preview.
    post story_group_student_currency_adjustment_path(@story_group, @student),
         params: { currency_adjustment: { sign: '-1', amount: '99' } }

    assert_select '[data-currency-adjust-target=preview][hidden]'
  end

  test 'a student cannot correct their own currency' do
    get new_story_group_student_currency_adjustment_path(@story_group, @student)
    assert_redirected_to root_path

    assert_no_difference('CurrencyTransaction.count') do
      post story_group_student_currency_adjustment_path(@story_group, @student),
           params: { currency_adjustment: { sign: '1', amount: '1000' } }
    end
    assert_redirected_to root_path
  end
end
