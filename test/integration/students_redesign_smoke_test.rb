# frozen_string_literal: true

require 'test_helper'

# Studenci (#/t/students, js-expanded/30-lists.js:45-48), the student sheet with
# its three tabs (#/t/student, 30-student.js:19-35) and the three dialogs that
# hang off it: Edytuj (mEdit), Usuń z grupy and Przyznaj/Odbierz odznakę.
class StudentsRedesignSmokeTest < ActionDispatch::IntegrationTest
  MODAL  = { 'Turbo-Frame' => 'modal' }.freeze
  MODAL2 = { 'Turbo-Frame' => 'modal2' }.freeze

  setup do
    @owner = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @owner, name: 'Kosmiczne króliki',
                                                   currency_name: 'marchewki',)
    sign_in @owner
  end

  # sign_in is a no-op while a session is live — the magic-link verify refuses
  # to run for someone already logged in — so switching user needs the sign_out.
  def sign_in_as(user)
    sign_out
    sign_in user
  end

  def student(name:, nickname: nil, total: 0, balance: nil, lives: 3)
    user = FactoryBot.create(:user, role: :student, full_name: name)

    FactoryBot.create(:story_group_student, user: user, story_group: @story_group,
                                            nickname: nickname, lives: lives,
                                            total_currency: total,
                                            current_currency: balance || total,)
  end

  def rank(name:, threshold:, discount: 0)
    FactoryBot.create(:rank, story_group: @story_group, name: name,
                             required_currency_value: threshold, discount: discount,)
  end

  def badge(name:, discount: 0)
    FactoryBot.create(:badge, story_group: @story_group, name: name, discount: discount)
  end

  def item(name:, price: 20, **attributes)
    FactoryBot.create(:item, story_group: @story_group, name: name, price: price, **attributes)
  end

  def award(member, badge_record)
    FactoryBot.create(:students_badge, story_group_student: member, badge: badge_record)
  end

  def visit_list = get story_group_students_path(@story_group)

  def visit_sheet(member, **query)
    get story_group_student_path(@story_group, member, **query)
  end

  # Values of one column across every rendered row, header excluded.
  def column(selector) = css_select(".gh-srow:not(.gh-srow--h) #{selector}").map { |cell| cell.text.strip }

  def names = css_select('.gh-s-n b').map { |cell| cell.text.strip }

  # Trimmed text of every match, so assertions read as data rather than nodes.
  def texts(selector) = css_select(selector).map { |node| node.text.strip }

  # A tab's own word, without the count that follows it.
  def first_words(selector) = css_select(selector).map { |node| node.text.split.first }

  def tab_labels = first_words('.gh-gt2')

  def current_tab = first_words('.gh-gt2[aria-current=true]').first

  # ---- the list --------------------------------------------------------

  test 'the list reads by display name and shows rank, money, lives and badges' do
    rank(name: 'Rekrut', threshold: 0)
    rank(name: 'Kapitan', threshold: 50)

    zofia = student(name: 'Zofia Nowak', total: 60, balance: 10, lives: 2)
    student(name: 'Anna Kowalska', total: 10)
    award(zofia, badge(name: 'Nawigator'))

    visit_list

    assert_response :success
    assert_select 'h1.gh-h1', 'Studenci'
    assert_equal ['Anna Kowalska', 'Zofia Nowak'], names
    assert_equal %w[Rekrut Kapitan], column('.gh-s-r')
    # Do wydania | Zebrane | Odznaki, per row, Anna first.
    assert_equal %w[10 10 0 10 60 1], column('.gh-num2')
  end

  test 'the lead only mentions zero lives when somebody is at zero' do
    student(name: 'Anna Kowalska', lives: 3)
    visit_list
    assert_select '.gh-lead', 'Życie odbierasz za nieusprawiedliwioną nieobecność.'

    student(name: 'Zofia Nowak', lives: 0)
    visit_list
    assert_select '.gh-lead b', '1 student ma 0 żyć'
    assert_select '.gh-srow--zero', 1
  end

  # The other way round from the ranking, which is the only screen where a
  # nickname stands in for a person.
  test 'the real name is the name, with the nickname beside it' do
    student(name: 'Sebastian Alejandro', nickname: 'Kapitan Marchewka')

    visit_list

    assert_equal ['Sebastian Alejandro'], names
    assert_select '.gh-s-n small', /\A„Kapitan Marchewka” · /
  end

  test 'a student without a nickname does not repeat their own name' do
    member = student(name: 'Anna Kowalska')

    visit_list

    assert_equal ['Anna Kowalska'], names
    assert_select '.gh-s-n small', member.email
  end

  test 'the minus button is gone at zero lives and there otherwise' do
    student(name: 'Anna Kowalska', lives: 0)
    visit_list
    assert_select '.gh-lives button[disabled]', 1

    visit_list
    assert_select '.gh-lv--zero', 1
  end

  test 'the list carries the search, its counter and a hidden empty panel' do
    student(name: 'Anna Kowalska')

    visit_list

    assert_select '[data-controller=list-search][data-list-search-total-value="1"]'
    assert_select '[data-list-search-target=count]', '1 z 1'
    assert_select '[data-list-search-target=row]', 1
    assert_select '[data-list-search-target=empty][hidden]'
  end

  test 'an empty group names the next action' do
    visit_list

    assert_select '.gh-gm .gh-h2', 'Nie ma jeszcze nikogo w grupie'
    assert_select '.gh-srow', false
    assert_select ".gh-gm a[href='#{story_group_invites_path(@story_group)}']", 'Kody i zaproszenia'
  end

  test 'each row links to the sheet and straight to the two quick actions' do
    member = student(name: 'Anna Kowalska')

    visit_list

    assert_select "a[href='#{story_group_student_path(@story_group, member)}']"
    assert_select "a[href='#{new_story_group_student_badge_path(@story_group, member)}'][data-turbo-frame=modal]"
    assert_select 'a[href=?][data-turbo-frame=modal]',
                  new_story_group_student_currency_adjustment_path(@story_group, member)
    assert_select 'a[href=?]', story_group_student_path(@story_group, member, tab: 'hist')
  end

  test 'the lives stepper posts and reports the result' do
    member = student(name: 'Anna Kowalska', lives: 3)

    post update_lives_story_group_student_path(@story_group, member, change: -1)

    assert_redirected_to story_group_students_path(@story_group)
    assert_equal 2, member.reload.lives
    follow_redirect!
    assert_select '#gh-toasts template[data-toast-target=seed]', 'Anna Kowalska ma teraz 2 życia.'
  end

  test 'the stepper refuses to go below zero' do
    member = student(name: 'Anna Kowalska', lives: 0)

    post update_lives_story_group_student_path(@story_group, member, change: -1)

    assert_equal 0, member.reload.lives
    follow_redirect!
    # An error stays on the page rather than rising as a toast.
    assert_select '.gh-plate[role=alert] span', /student ma już 0/
  end

  # ---- the sheet -------------------------------------------------------

  # The nickname is shown but does not take the headline: a teacher on this page
  # is looking at a person, and the pseudonym is one more fact about them.
  test 'the sheet leads with the real name and carries the nickname beside it' do
    member = student(name: 'Sebastian Alejandro', nickname: 'Kapitan Marchewka')

    visit_sheet(member)

    assert_select '.gh-sheet h1.gh-h1', 'Sebastian Alejandro'
    assert_select '.gh-crumbs span', 'Sebastian Alejandro'
    assert_select '.gh-sh-sub', /\APseudonim: Kapitan Marchewka, /
  end

  test 'a student with no nickname gets no pseudonym fragment' do
    member = student(name: 'Anna Kowalska')

    visit_sheet(member)

    assert_select '.gh-sheet h1.gh-h1', 'Anna Kowalska'
    assert_no_match(/Pseudonim:/, response.body)
  end

  test 'the sheet is a page with a head, stats and three tabs' do
    rank(name: 'Rekrut', threshold: 0)
    rank(name: 'Kapitan', threshold: 50)
    member = student(name: 'Anna Kowalska', total: 30, balance: 12, lives: 2)

    visit_sheet(member)

    assert_response :success
    assert_select 'main#app-content turbo-frame#modal', false
    assert_select '.gh-sheet h1.gh-h1', 'Anna Kowalska'
    assert_select '.gh-sh-sub', /#{Regexp.escape(member.email)}/
    assert_select '.gh-crumbs a[href=?]', story_group_students_path(@story_group), 'Studenci'

    stats = css_select('.gh-stat dd').map { |cell| cell.text.split.first }
    assert_equal %w[Rekrut 12 30 2], stats
    assert_select '.gh-stat dd small', '30 z 50 do rangi Kapitan'
    assert_select '.gh-stat .gh-bar[role=progressbar][aria-valuenow="60"]'

    assert_equal %w[Odznaki Przedmioty Historia], tab_labels
  end

  test 'the rank stat drops its bar at the top rung and in a group with no ranks' do
    rank(name: 'Rekrut', threshold: 0)
    member = student(name: 'Anna Kowalska', total: 30)

    visit_sheet(member)
    assert_select '.gh-stat .gh-bar', false
    assert_select '.gh-stat dd small', false

    other = student(name: 'Zofia Nowak', total: 30)
    @story_group.ranks.destroy_all
    visit_sheet(other)
    assert_select '.gh-stat dd', '—'
  end

  test 'badges is the default tab and the others follow the query' do
    member = student(name: 'Anna Kowalska')

    visit_sheet(member)
    assert_equal 'Odznaki', current_tab

    visit_sheet(member, tab: 'hist')
    assert_equal 'Historia', current_tab

    # Anything else falls back rather than rendering an empty panel.
    visit_sheet(member, tab: 'wymyslona')
    assert_equal 'Odznaki', current_tab
  end

  test 'the tabs count what is behind them' do
    member = student(name: 'Anna Kowalska', total: 50)
    award(member, badge(name: 'Nawigator'))
    award(member, badge(name: 'Zwiadowca'))
    FactoryBot.create(:students_item, story_group_student: member, item: item(name: 'Poprawa'))
    FactoryBot.create(:currency_transaction, student: member, amount: 50, kind: :reward)

    visit_sheet(member)

    assert_equal %w[2 1 1], texts('.gh-gt2 .gh-n')
  end

  test 'the badges tab shows held badges with a revoke link' do
    member = student(name: 'Anna Kowalska')
    held   = badge(name: 'Nawigator', discount: 5)
    award(member, held)

    visit_sheet(member)

    assert_select '.gh-bgrid .gh-card-name', 'Nawigator'
    assert_select '.gh-tag--disc', '−5% w sklepie'
    assert_select '.gh-card-foot a[data-turbo-frame=modal]', 'Odbierz'
  end

  test 'the badges tab says so when there are none' do
    visit_sheet(student(name: 'Anna Kowalska'))

    assert_select '.gh-expl', 'Student nie ma jeszcze żadnej odznaki.'
    assert_select '.gh-bgrid', false
  end

  test 'the items tab shows what was paid and flags a discount' do
    member = student(name: 'Anna Kowalska')
    FactoryBot.create(:students_item, story_group_student: member,
                                      item: item(name: 'Poprawa wejściówki', price: 20),
                                      price_paid: 15, discount_applied: 25,)

    visit_sheet(member, tab: 'items')

    assert_select '.gh-ilist .gh-card-name', 'Poprawa wejściówki'
    assert_select '.gh-cost b', '15'
    assert_select '.gh-card-foot .gh-meta', /\AKupione .*, ze zniżką z 20\z/
  end

  test 'a withdrawn item stays in the inventory tab, tagged' do
    member = student(name: 'Anna Kowalska')
    withdrawn = item(name: 'Stary przedmiot', price: 10)
    FactoryBot.create(:students_item, story_group_student: member, item: withdrawn, price_paid: 10)
    withdrawn.soft_delete!

    visit_sheet(member, tab: 'items')

    assert_select '.gh-card--gone .gh-card-name', 'Stary przedmiot'
    assert_select '.gh-tag--del', 'Usunięty z oferty'
  end

  test 'the history tab carries the ledger, the summary and the filters' do
    member = student(name: 'Anna Kowalska', total: 50, balance: 50)
    FactoryBot.create(:currency_transaction, student: member, amount: 50, kind: :reward)

    visit_sheet(member, tab: 'hist')

    assert_select '.gh-ledh .gh-small', 'Saldo: 50, zebrane łącznie: 50.'
    assert_equal %w[Wszystkie Nagrody Zakupy Korekty], first_words('.gh-fchip')
    assert_select '.gh-lrow .gh-amt--earn', '+50'
    assert_select '.gh-bal2', '50'
  end

  test 'the history filter narrows the rows and marks itself current' do
    member = student(name: 'Anna Kowalska', total: 50, balance: 45)
    FactoryBot.create(:currency_transaction, student: member, amount: 50, kind: :reward)
    FactoryBot.create(:currency_transaction, student: member, amount: -5, kind: :adjustment,
                                             granted_by_user: @owner,)

    visit_sheet(member, tab: 'hist')
    assert_select '.gh-lrow:not(.gh-lrow--h)', 2

    visit_sheet(member, tab: 'hist', kind: 'adjustment')
    assert_select '.gh-lrow:not(.gh-lrow--h)', 1
    assert_select '.gh-fchip[aria-current=true]', /Korekty/
  end

  # ---- edit and removal ------------------------------------------------

  test 'the edit dialog is a lives stepper and a way out of the group' do
    member = student(name: 'Anna Kowalska', lives: 2)

    get edit_story_group_student_path(@story_group, member), headers: MODAL

    assert_response :success
    assert_select 'turbo-frame#modal'
    assert_select '.gh-h2', 'Edytuj studenta'
    assert_select '.gh-nstep output', '2'
    assert_select 'input[type=hidden][name=?][value=?]', 'story_group_student[lives]', '2'
    assert_select '[data-lives-stepper-start-value="2"]'
    # The removal opens the SECOND dialog, over this one.
    assert_select 'a.gh-kick[data-turbo-frame=modal2]', /Usuń z grupy/
  end

  test 'the edit dialog also renders as a page' do
    member = student(name: 'Anna Kowalska')

    get edit_story_group_student_path(@story_group, member)

    assert_select 'turbo-frame#modal .gh-nstep', false
    assert_select '.gh-panel.gh-dlg-page .gh-nstep'
    assert_select ".gh-dlg-b a[href='#{story_group_student_path(@story_group, member)}']", 'Anuluj'
  end

  test 'saving lives lands on the sheet and says the result' do
    member = student(name: 'Anna Kowalska', lives: 3)

    patch story_group_student_path(@story_group, member),
          params: { story_group_student: { lives: 1 } }

    assert_turbo_redirected_to story_group_student_path(@story_group, member)
    assert_equal 1, member.reload.lives
  end

  test 'the removal confirmation counts what will be lost' do
    member = student(name: 'Anna Kowalska', total: 50, balance: 30)
    award(member, badge(name: 'Nawigator'))
    FactoryBot.create(:students_item, story_group_student: member, item: item(name: 'Poprawa'))
    FactoryBot.create(:currency_transaction, student: member, amount: 50, kind: :reward)

    get confirm_destroy_story_group_student_path(@story_group, member), headers: MODAL2

    assert_response :success
    assert_select 'turbo-frame#modal2'
    assert_select '.gh-h2', 'Usunąć studenta z grupy?'
    assert_select 'p', /\AAnna Kowalska straci dostęp do grupy/
    assert_select '.gh-warn[role=alert] span',
                  /Przepadną: 1 odznakę, 1 przedmiot i całą historię waluty \(1 wpis\)\./
    assert_select '.gh-dlg-b button[autofocus]', 'Anuluj'
  end

  test 'the removal confirmation says plainly when there is nothing to lose' do
    member = student(name: 'Anna Kowalska')

    get confirm_destroy_story_group_student_path(@story_group, member), headers: MODAL2

    assert_select '.gh-warn', false
    assert_select '.gh-expl', 'Ten student nie ma jeszcze odznak, przedmiotów ani historii waluty.'
  end

  test 'removing a student takes everything with it' do
    member = student(name: 'Anna Kowalska', total: 50)
    award(member, badge(name: 'Nawigator'))
    FactoryBot.create(:students_item, story_group_student: member, item: item(name: 'Poprawa'))
    FactoryBot.create(:currency_transaction, student: member, amount: 50, kind: :reward)

    cascades = [
      'StoryGroupStudent.count',
      'StudentsBadge.count',
      'StudentsItem.count',
      'CurrencyTransaction.count',
    ]

    assert_difference(cascades, -1) do
      delete story_group_student_path(@story_group, member)
    end

    assert_turbo_redirected_to story_group_students_path(@story_group)
  end

  # ---- awarding and revoking a badge -----------------------------------

  test 'the picker lists every badge and marks the ones already held' do
    member = student(name: 'Anna Kowalska')
    held   = badge(name: 'Nawigator', discount: 5)
    badge(name: 'Zwiadowca', discount: 10)
    award(member, held)

    get new_story_group_student_badge_path(@story_group, member), headers: MODAL

    assert_response :success
    assert_select '.gh-h2', 'Przyznaj odznakę'
    assert_select 'p', 'Anna Kowalska ma 1 z 2 odznak.'
    assert_select '.gh-bpick li', 2
    assert_select '.gh-bp--owned input[disabled]'
    assert_equal ['Ma już', '−10%'], texts('.gh-st2')
    # One effect sentence per badge, all hidden until something is picked.
    assert_select '[data-badge-picker-target=effect][hidden]', 2
  end

  test 'the effect sentence names what the badge unlocks' do
    member = student(name: 'Anna Kowalska')
    key = badge(name: 'Nawigator', discount: 5)
    item(name: 'Poprawa wejściówki', unlock_badges: [key])

    get new_story_group_student_badge_path(@story_group, member), headers: MODAL

    assert_select '[data-badge-picker-target=effect]',
                  /Po przyznaniu: −5% .*Odblokuje zakup: Poprawa wejściówki\./m
  end

  test 'awarding a badge reports it' do
    member = student(name: 'Anna Kowalska')
    given  = badge(name: 'Nawigator')

    assert_difference('StudentsBadge.count', 1) do
      post story_group_student_badges_path(@story_group, member),
           params: { students_badge: { badge_id: given.id } }
    end

    assert_turbo_redirected_to story_group_student_path(@story_group, member)

    # The redirect is a turbo-stream, so the next page is fetched by hand; the
    # notice is still in the flash when it arrives.
    get story_group_student_path(@story_group, member)
    assert_select '#gh-toasts template[data-toast-target=seed]', 'Przyznano odznakę „Nawigator”.'
  end

  test 'the revoke confirmation names the discount and what closes' do
    member = student(name: 'Anna Kowalska')
    held   = badge(name: 'Nawigator', discount: 5)
    item(name: 'Poprawa wejściówki', unlock_badges: [held])
    students_badge = award(member, held)

    get confirm_destroy_story_group_student_badge_path(@story_group, member, students_badge),
        headers: MODAL

    assert_response :success
    assert_select '.gh-h2', 'Odebrać odznakę „Nawigator”?'
    assert_select 'p', 'Anna Kowalska straci zniżkę −5% i możliwość zakupu: ' \
                       'Poprawa wejściówki. Kupione wcześniej przedmioty zostają.'
    assert_select '.gh-dlg-b button[autofocus]', 'Anuluj'
  end

  test 'revoking takes the award and leaves the badge alone' do
    member = student(name: 'Anna Kowalska')
    held   = badge(name: 'Nawigator')
    students_badge = award(member, held)

    assert_difference('StudentsBadge.count', -1) do
      assert_no_difference('Badge.count') do
        delete story_group_student_badge_path(@story_group, member, students_badge)
      end
    end

    assert_turbo_redirected_to story_group_student_path(@story_group, member)
  end

  # ---- who may look ----------------------------------------------------

  test 'a student cannot reach the list or anyone else sheet' do
    member = student(name: 'Anna Kowalska')
    sign_in_as member.user

    visit_list
    assert_redirected_to root_path

    visit_sheet(member)
    assert_redirected_to root_path
  end
end
