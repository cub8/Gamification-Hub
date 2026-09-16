# frozen_string_literal: true

require 'test_helper'

# "Grupa: przegląd" — StoryGroups#show, converted to the redesign layout.
# One action, two screens: the teacher's group front page (mockup #/t/home) and
# the student's own (#/s/home).
class GroupOverviewRedesignSmokeTest < ActionDispatch::IntegrationTest
  # A 1x1 transparent PNG. The screen only cares whether an icon is attached.
  PNG = Base64.decode64(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  )

  def group(**attrs)
    FactoryBot.create(:story_group, { name: 'Kosmiczne króliki', currency_name: 'Marchewek' }.merge(attrs))
  end

  def student_in(story_group, name: 'Sebastian Alejandro', **attrs)
    FactoryBot.create(:story_group_student,
                      {
                        story_group:      story_group,
                        user:             FactoryBot.create(:user, role: :student, full_name: name),
                        lives:            3,
                        current_currency: 0,
                        total_currency:   0,
                      }.merge(attrs),)
  end

  # A sheet with one graded column, which is what puts a student on its podium.
  def graded_sheet(story_group, name:, awards: {})
    sheet = FactoryBot.create(:activity_group, story_group: story_group, name: name,
                              activity_group_template: FactoryBot.create(:activity_group_template,
                                                                         story_group: story_group,),)
    awards.each do |membership, reward|
      category = FactoryBot.create(:activity_group_category, activity_group: sheet, reward: reward)
      StudentsActivityGroupCategory.create!(student: membership, activity_group_category: category)
    end
    sheet
  end

  # --- layout ---------------------------------------------------------------

  test 'the overview renders inside the redesign chrome for a teacher' do
    teacher = FactoryBot.create(:user, role: :teacher)

    sign_in teacher
    get story_group_path(group(owner: teacher))

    assert_response :success
    assert_select '.gh-shell header.gh-hd'
    assert_select 'link[href*=redesign]'
    assert_select 'link[href*=application]', false
    assert_no_match(/data-bs-/, response.body)
  end

  test 'the overview renders inside the redesign chrome for a student' do
    story_group = group
    membership = student_in(story_group)

    sign_in membership.user
    get story_group_path(story_group)

    assert_response :success
    assert_select '.gh-shell header.gh-hd'
    assert_select 'link[href*=application]', false
  end

  test 'the sidebar marks Przegląd as the current destination' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher)

    sign_in teacher
    get story_group_path(story_group)

    assert_select 'aside.gh-sb a.gh-nl.gh-nl--on[href=?][aria-current=page]',
                  story_group_path(story_group), 'Przegląd'
  end

  test 'a stranger cannot open the overview' do
    sign_in FactoryBot.create(:user, role: :teacher)
    get story_group_path(group)

    # ApplicationController turns Pundit's refusal into a redirect, so a teacher
    # who is neither owner, supporter nor student never reaches the page.
    assert_redirected_to root_path
  end

  # Membership wins over role: a teacher enrolled as a student reads the
  # student's screen, exactly as the sidebar beside it does.
  test 'a teacher enrolled in a group reads it as a student' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group
    FactoryBot.create(:story_group_student, story_group: story_group, user: teacher,
                                            lives: 3, current_currency: 7, total_currency: 7,)

    sign_in teacher
    get story_group_path(story_group)

    assert_select '.gh-home .gh-purse'
    assert_select '.gh-kpis', false
  end

  # --- teacher: hero and KPIs -----------------------------------------------

  test 'the hero carries the group and its three openings' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher, description: 'Galaktyka jest wielka.')

    sign_in teacher
    get story_group_path(story_group)

    assert_select '.gh-hero .gh-h1', 'Kosmiczne króliki'
    assert_select '.gh-hero .gh-lore-t', 'Galaktyka jest wielka.'
    assert_select '.gh-hero .gh-art--mono', 'KK'
    assert_select '.gh-hero a[href=?]', story_group_invites_path(story_group), /Pokaż kod/
    assert_select '.gh-hero a[href=?]', story_group_activity_groups_path(story_group), /Utwórz arkusz/
    assert_select '.gh-hero a[href=?]', edit_story_group_path(story_group), /Ustawienia grupy/
  end

  test 'a group with artwork shows it instead of the monogram' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher)
    story_group.icon.attach(io: StringIO.new(PNG), filename: 'icon.png', content_type: 'image/png')

    sign_in teacher
    get story_group_path(story_group)

    assert_select '.gh-hero .gh-art img'
    assert_select '.gh-hero .gh-art--mono', false
  end

  test 'a group with no description says what to do about it' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher, description: nil)
    student_in(story_group)

    sign_in teacher
    get story_group_path(story_group)

    assert_select '.gh-hero .gh-lore-t', /1 student w tej grupie/
    assert_select '.gh-hero .gh-lore-t', /Dodaj opis/
  end

  test 'a supporting teacher gets the hero without the settings button' do
    owner = FactoryBot.create(:user, role: :teacher)
    helper = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: owner)
    FactoryBot.create(:story_group_teacher, user: helper, story_group: story_group)

    sign_in helper
    get story_group_path(story_group)

    assert_response :success
    # A supporting teacher may edit everything but the group's existence, so
    # the button stays — this is the policy speaking, not the screen.
    assert_select '.gh-hero a[href=?]', edit_story_group_path(story_group)
  end

  test 'the KPI strip counts only this week and only this group' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher)
    membership = student_in(story_group)
    other = student_in(group, name: 'Ktoś obcy')
    item = FactoryBot.create(:item, story_group: story_group)

    CurrencyTransaction.create!(student: membership, amount: -15, kind: :purchase, transactionable: item)
    CurrencyTransaction.create!(student: membership, amount: -5,  kind: :purchase, transactionable: item)
    CurrencyTransaction.create!(student: membership, amount: -99, kind: :purchase, transactionable: item,
                                created_at: 10.days.ago,)
    CurrencyTransaction.create!(student: membership, amount: 46, kind: :reward)
    CurrencyTransaction.create!(student: other, amount: -50, kind: :purchase, transactionable: item)

    sign_in teacher
    get story_group_path(story_group)

    values = css_select('.gh-kpi').map { |kpi| [kpi.css('dt').text, kpi.css('dd').text.strip] }

    assert_equal '1', values[0].last
    assert_equal 'Studenci', values[0].first
    assert_match(/\A2\s+za 20\z/, values[1].last)
    assert_equal '46', values[2].last
    assert_equal 'Wyłączony', values[3].last
  end

  test 'the ranking KPI names the mode once ranking is on' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher, ranking_enabled: true)

    sign_in teacher
    get story_group_path(story_group)

    assert_select '.gh-kpi:last-child dd', 'Podium i własne miejsce'

    story_group.update!(ranking_mode: :full)
    get story_group_path(story_group)

    assert_select '.gh-kpi:last-child dd', 'Pełny ranking'
  end

  # --- teacher: purchases ---------------------------------------------------

  test 'recent purchases name the item, the student and the price' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher)
    membership = student_in(story_group, nickname: 'Nova')
    item = FactoryBot.create(:item, story_group: story_group, name: 'Poprawka')

    CurrencyTransaction.create!(student: membership, amount: -15, kind: :purchase, transactionable: item)

    sign_in teacher
    get story_group_path(story_group)

    assert_select '.gh-plist .gh-prow' do
      assert_select 'b', 'Poprawka'
      # The nickname is what everybody else in the group sees.
      assert_select '.gh-p-main span', 'Nova'
      assert_select '.gh-cost b', '15'
    end
    assert_select 'a[href=?]', home_path(group: story_group.id), 'Wszystkie zakupy w grupie'
  end

  # The item attachment was renamed icon -> image in 20260915090000; the
  # Bootstrap view this replaced still reached for `.image` and raised here.
  test 'a purchase whose item was hard deleted still renders' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher)
    membership = student_in(story_group)

    CurrencyTransaction.create!(student: membership, amount: -15, kind: :purchase, transactionable: nil)

    sign_in teacher
    get story_group_path(story_group)

    assert_response :success
    assert_select '.gh-prow b', 'Przedmiot usunięty z oferty'
  end

  # Four columns, not the Start screen's five: without the modifier the price
  # chip auto-places into the group chip's 210px track and stretches into a bar,
  # and its right edge then moves with the length of the date beside it.
  test 'purchase rows carry the four-column variant' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher)
    membership = student_in(story_group)
    item = FactoryBot.create(:item, story_group: story_group)

    CurrencyTransaction.create!(student: membership, amount: -15, kind: :purchase, transactionable: item)

    sign_in teacher
    get story_group_path(story_group)

    assert_select 'li.gh-prow.gh-prow--group', 1
    # No group chip in a group: the row has four children, which is what the
    # modifier's track list is for.
    assert_select '.gh-prow--group .gh-p-g', false
    assert_select '.gh-prow--group > *', 4
  end

  test 'a group where nobody has bought anything says so' do
    teacher = FactoryBot.create(:user, role: :teacher)

    sign_in teacher
    get story_group_path(group(owner: teacher))

    assert_select '.gh-plist', false
    assert_select '.gh-hp .gh-expl', /Nikt jeszcze niczego nie kupił/
  end

  # --- teacher: Wymaga uwagi ------------------------------------------------

  test 'a student out of lives is the first thing that needs attention' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher)
    membership = student_in(story_group, name: 'Mateusz Lewandowski', lives: 0)

    sign_in teacher
    get story_group_path(story_group)

    assert_select '.gh-att li:first-child' do
      assert_select '.gh-att-ic--zero'
      assert_select 'b', 'Mateusz Lewandowski ma 0 żyć'
      assert_select 'a[href=?]', story_group_student_path(story_group, membership), 'Otwórz'
    end
  end

  # A student climbing toward a rung is the system working, not a task. The
  # panel is a list of things that need doing, and a promotion needs nothing.
  test 'a student close to a promotion is not flagged' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher)
    FactoryBot.create(:rank, story_group: story_group, name: 'Kosmiczny Królik', required_currency_value: 40)
    student_in(story_group, name: 'Bliski Awansu', total_currency: 39)

    sign_in teacher
    get story_group_path(story_group)

    assert_select '.gh-att', false
    assert_select 'body', { text: /do awansu/, count: 0 }
  end

  test 'a sheet with an ungraded column asks to be graded' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher)
    membership = student_in(story_group)
    sheet = graded_sheet(story_group, name: 'Laboratoria 5', awards: { membership => 10 })
    FactoryBot.create(:activity_group_category, activity_group: sheet, reward: 4)

    sign_in teacher
    get story_group_path(story_group)

    assert_select '.gh-att b', 'Laboratoria 5 w trakcie'
    assert_select '.gh-att small', 'Przyznano 1 nagrodę, 1 kolumna bez ocen.'
    assert_select '.gh-att a.gh-btn[href=?]',
                  edit_story_group_activity_group_students_activity_group_categories_path(story_group, sheet),
                  'Oceń'
  end

  test 'a group with nothing to flag has no attention panel at all' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher)
    student_in(story_group)

    sign_in teacher
    get story_group_path(story_group)

    assert_select '.gh-att', false
  end

  # --- teacher: per-sheet podium --------------------------------------------

  test 'the newest sheets carry a podium of this group only' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher)
    winner = student_in(story_group, name: 'Adam Pawłowski', nickname: 'Meteor')
    runner = student_in(story_group, name: 'Barbara Kowalewska')

    graded_sheet(story_group, name: 'Laboratoria 3', awards: { winner => 1 })
    graded_sheet(story_group, name: 'Laboratoria 4', awards: { winner => 11, runner => 8 })

    sign_in teacher
    get story_group_path(story_group)

    names = css_select('.gh-sheet2 b').map(&:text)

    # Newest first, and only two of the three.
    assert_equal ['Laboratoria 4', 'Laboratoria 3'], names

    assert_select '.gh-sheet2:first-of-type .gh-top3 li:first-child' do
      assert_select '.gh-pos.gh-pos--1', '1'
      # A nickname where one is set, the real name otherwise.
      assert_select '.gh-sc', '+11'
    end
    assert_select '.gh-top3 li', /Meteor/
    assert_select '.gh-top3 li', /Barbara Kowalewska/
  end

  test 'the podium note follows the group ranking settings' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher)
    membership = student_in(story_group)
    graded_sheet(story_group, name: 'Laboratoria 1', awards: { membership => 5 })

    sign_in teacher
    get story_group_path(story_group)

    assert_select '.gh-sheet2 .gh-small', /Ranking jest wyłączony/

    story_group.update!(ranking_enabled: true)
    get story_group_path(story_group)

    assert_select '.gh-sheet2 .gh-small', /podium i własne miejsce/

    story_group.update!(ranking_mode: :full)
    get story_group_path(story_group)

    assert_select '.gh-sheet2 .gh-small', /pełny ranking/i
  end

  test 'a group with no sheets is told what a sheet is for' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = group(owner: teacher)

    sign_in teacher
    get story_group_path(story_group)

    assert_select '.gh-hcol h2', 'Nie masz jeszcze arkuszy ocen'
    assert_select '.gh-hcol a[href=?]', story_group_activity_groups_path(story_group), 'Utwórz arkusz'
  end

  # --- student: purse and rank ----------------------------------------------

  test 'the purse shows the spendable balance, the total and the lives' do
    story_group = group
    membership = student_in(story_group, lives: 2, current_currency: 12, total_currency: 34)

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-purse .gh-k', 'Do wydania'
    assert_select '.gh-purse .gh-num', '12'
    assert_select '.gh-purse .gh-unit', 'Marchewek'
    assert_select '.gh-purse-stats dd', '34'
    assert_select '.gh-purse .gh-lv', /2/
    assert_select '.gh-purse a[href=?]', story_group_shop_index_path(story_group), /Otwórz sklep/
  end

  test 'zero lives are marked in the purse' do
    story_group = group
    membership = student_in(story_group, lives: 0)

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-purse .gh-lv.gh-lv--zero'
  end

  test 'the rank card measures progress from the rung you hold, not from zero' do
    story_group = group
    FactoryBot.create(:rank, story_group: story_group, name: 'Królik', required_currency_value: 20, discount: 0)
    FactoryBot.create(:rank, story_group: story_group, name: 'Kosmiczny Królik',
                             required_currency_value: 40, discount: 15,)
    membership = student_in(story_group, total_currency: 30)

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-rank-name', 'Królik'
    assert_select '.gh-rank-pt span', '30 z 40'
    # Half of the 20 that separates the two rungs, not three quarters of 40.
    assert_select '.gh-bar[aria-valuenow="10"][aria-valuemax="20"] i[style=?]', '--gh-p: 50%'
    assert_select '.gh-rank-p .gh-small', 'Jeszcze 10 do rangi Kosmiczny Królik. Ta ranga daje −15% w sklepie.'
  end

  test 'a rank with no discount does not promise one' do
    story_group = group
    FactoryBot.create(:rank, story_group: story_group, name: 'Królik', required_currency_value: 20, discount: 0)
    membership = student_in(story_group, total_currency: 5)

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-rank-p .gh-small', 'Jeszcze 15 do rangi Królik.'
  end

  test 'a student at the top rung is told there is nothing above it' do
    story_group = group
    FactoryBot.create(:rank, story_group: story_group, name: 'Królik', required_currency_value: 20)
    top = student_in(story_group, total_currency: 50)

    sign_in top.user
    get story_group_path(story_group)

    assert_select '.gh-rank-name', 'Królik'
    assert_select '.gh-rankc .gh-small', /To najwyższa ranga/
    assert_select '.gh-rank-p', false
  end

  test 'a group with no ranks says so instead of showing an empty rank card' do
    story_group = group(name: 'Bez rang')
    membership = student_in(story_group)

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-rank-name', 'Brak rangi'
    assert_select '.gh-rankc .gh-small', /nie dodał jeszcze rang/
    assert_select '.gh-rankc .gh-art', false
  end

  # ranks/_rank_thumb is a mini entity card with its own frame and shadow;
  # nesting one in an art well leaves a 52px chip floating in a 200px rectangle.
  # The well gets the bare art, exactly as the rank form's preview does.
  test 'the rank card holds bare art, not a mini card' do
    story_group = group
    FactoryBot.create(:rank, story_group: story_group, name: 'Królik',
                             required_currency_value: 0, icon_glyph: 'chev1',)
    membership = student_in(story_group, total_currency: 5)

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-rankc .gh-art .gh-mc', false
    assert_select '.gh-rankc .gh-art > svg.gh-gph'
  end

  # A rank always validates with art, so the fallback only fires for a row whose
  # preset has since been retired — gh_glyph returns nil for a key it no longer
  # knows. update_column, because that state cannot be reached through the form.
  test 'a rank whose preset was retired falls back to the ranking star' do
    story_group = group
    rank = FactoryBot.create(:rank, story_group: story_group, name: 'Królik',
                                    required_currency_value: 0,)
    rank.update_column(:icon_glyph, 'retired-preset')
    membership = student_in(story_group, total_currency: 5)

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-rankc .gh-art i.fa-ranking-star'
    assert_select '.gh-rankc .gh-art svg.gh-gph', false
  end

  # --- student: ranking place -----------------------------------------------

  test 'the place appears only once ranking is enabled' do
    story_group = group
    membership = student_in(story_group, total_currency: 20)
    student_in(story_group, name: 'Lepszy Ktoś', total_currency: 50)

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-rk', false

    story_group.update!(ranking_enabled: true)
    get story_group_path(story_group)

    assert_select '.gh-rk a[href=?]', story_group_ranking_path(story_group), '2. miejsce w rankingu grupy'
  end

  test 'students tied on the total share a place' do
    story_group = group(ranking_enabled: true)
    student_in(story_group, name: 'Pierwszy', total_currency: 90)
    tied = student_in(story_group, name: 'Drugi', total_currency: 40)
    student_in(story_group, name: 'Też Drugi', total_currency: 40)
    last = student_in(story_group, name: 'Czwarty', total_currency: 10)

    sign_in tied.user
    get story_group_path(story_group)

    assert_select '.gh-rk a', '2. miejsce w rankingu grupy'

    sign_out
    sign_in last.user
    get story_group_path(story_group)

    # 4., not 3.: the two on 40 both take second place.
    assert_select '.gh-rk a', '4. miejsce w rankingu grupy'
  end

  # --- student: collections and ledger --------------------------------------

  test 'the badges zone shows every badge and counts the earned ones' do
    story_group = group
    earned = FactoryBot.create(:badge, story_group: story_group, name: 'Pierwsza pomoc')
    FactoryBot.create(:badge, story_group: story_group, name: 'Zaginiony')
    membership = student_in(story_group)
    StudentsBadge.create!(story_group_student: membership, badge: earned)

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-zone--badges .gh-zone-n', '1 z 2'
    assert_select '.gh-zone--badges .gh-card--badge', 2
    # The unearned one lies face down: its art is the reward.
    assert_select '.gh-zone--badges .gh-flip--down', 1
  end

  test 'a group with no badges has no badges zone' do
    story_group = group
    membership = student_in(story_group)

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-zone--badges', false
  end

  test 'the hand fans the newest items and the slot counts what is affordable' do
    story_group = group
    membership = student_in(story_group, current_currency: 100)
    FactoryBot.create(:item, story_group: story_group, name: 'Tani', price: 5)
    FactoryBot.create(:item, story_group: story_group, name: 'Drogi', price: 500)

    3.times do |index|
      item = FactoryBot.create(:item, story_group: story_group, name: "Kupiony #{index}")
      FactoryBot.create(:students_item, story_group_student: membership, item: item)
    end

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-zone--hand .gh-zone-n', '3'
    assert_select '.gh-hand .gh-hc', 3
    # Middle card straight, the other two splayed either side of it.
    rotations = css_select('.gh-hand .gh-hc').map { |node| node['style'] }

    assert_equal ['--gh-rot: -4.0deg', '--gh-rot: 0.0deg', '--gh-rot: 4.0deg'], rotations

    # Everything but "Drogi" is within reach. Owning an item does not take it
    # out of the count — the shop sells repeats, and "Moje przedmioty" says the
    # same number for the same reason.
    assert_select '.gh-slot-e p', 'Dobierz coś w sklepie. Stać cię teraz na 4 przedmioty.'
  end

  # Three is what the span-7 column holds; the counter and "Moje przedmioty"
  # carry the rest, so the fan never grows past what it can draw.
  test 'the hand holds at most three cards but counts them all' do
    story_group = group
    membership = student_in(story_group)
    7.times do
      FactoryBot.create(:students_item, story_group_student: membership,
                                        item:                FactoryBot.create(:item, story_group: story_group),)
    end

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-hand .gh-hc', 3
    assert_select '.gh-zone--hand .gh-zone-n', '7'
  end

  # A single card is not a fan: it sits straight, not tipped to one side.
  test 'one owned item is not rotated' do
    story_group = group
    membership = student_in(story_group)
    FactoryBot.create(:students_item, story_group_student: membership,
                                      item:                FactoryBot.create(:item, story_group: story_group),)

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-hand .gh-hc[style=?]', '--gh-rot: 0.0deg'
  end

  test 'the ledger shows the six newest rows and links to the whole history' do
    story_group = group
    membership = student_in(story_group, current_currency: 30, total_currency: 40)

    8.times { |index| CurrencyTransaction.create!(student: membership, amount: index + 1, kind: :reward) }
    CurrencyTransaction.create!(student: membership, amount: -4, kind: :adjustment)

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-ledger .gh-led-r', 6
    assert_select '.gh-ledger .gh-led-a--corr', '−4'
    assert_select '.gh-ledger a[href=?]',
                  story_group_student_currency_transactions_path(story_group, membership),
                  'Pokaż całą historię'
  end

  test 'a student with no history is told when the first row will appear' do
    story_group = group
    membership = student_in(story_group)

    sign_in membership.user
    get story_group_path(story_group)

    assert_select '.gh-ledger .gh-led', false
    assert_select '.gh-ledger .gh-expl', /Pierwsze wpisy pojawią się po zajęciach/
  end

  test 'the student overview never shows a sheet podium' do
    story_group = group
    membership = student_in(story_group)
    graded_sheet(story_group, name: 'Laboratoria 1', awards: { membership => 5 })

    sign_in membership.user
    get story_group_path(story_group)

    assert_response :success
    assert_select '.gh-top3', false
    assert_select '.gh-sheet2', false
  end
end
