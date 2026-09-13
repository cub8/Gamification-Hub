# frozen_string_literal: true

require 'test_helper'

class StartRedesignSmokeTest < ActionDispatch::IntegrationTest
  # --- chrome ---------------------------------------------------------------

  test 'the landing screen renders inside the redesign chrome' do
    sign_in FactoryBot.create(:user, role: :student)
    get home_path

    assert_response :success
    assert_select 'link[href*=redesign]'
    assert_select 'script[src*=redesign]'

    # The three chrome surfaces the auth screens never had.
    assert_select 'header.gh-hd'
    assert_select 'aside.gh-sb nav.gh-nav--primary'
    assert_select 'nav.gh-tabbar'

    # The texture belongs to the content well, not the whole page: the header
    # and sidebar sit on flat chrome colour.
    assert_select '.gh-tw > .gh-tpat.gh-tpat--well'
    assert_select 'body > .gh-tpat', false

    # No Bootstrap on this page any more.
    assert_select 'link[href*=application]', false
    assert_no_match(/data-bs-/, response.body)
  end

  test 'the primary nav names both destinations and marks the current one' do
    sign_in FactoryBot.create(:user, role: :student)
    get home_path

    assert_select 'aside.gh-sb a.gh-nl', 2
    assert_select 'aside.gh-sb a.gh-nl.gh-nl--on[href=?][aria-current=page]', home_path, 'Start'
    assert_select 'aside.gh-sb a.gh-nl[href=?]', story_groups_path, 'Grupy'
  end

  test 'the sidebar lists the groups the user belongs to, with their role' do
    teacher = FactoryBot.create(:user, role: :teacher)
    owned = FactoryBot.create(:story_group, owner: teacher, name: 'Alfa')
    supported = FactoryBot.create(:story_group, name: 'Beta')
    FactoryBot.create(:story_group_teacher, user: teacher, story_group: supported)

    sign_in teacher
    get home_path

    assert_select '.gh-glist a.gh-gl', 2
    assert_select '.gh-glist a.gh-gl[href=?]', story_group_path(owned) do
      assert_select 'small', 'Prowadzisz'
    end
    assert_select '.gh-glist a.gh-gl[href=?]', story_group_path(supported) do
      assert_select 'small', 'Wspierasz'
    end
  end

  test 'the collapsed sidebar follows the cookie both layouts share' do
    sign_in FactoryBot.create(:user, role: :student)

    get home_path
    assert_select 'aside.gh-sb:not(.gh-sb--collapsed)'
    assert_select '.gh-sb-col[aria-expanded=true]'

    cookies[:sidebar_collapsed] = 'true'
    get home_path
    assert_select 'aside.gh-sb.gh-sb--collapsed'
    assert_select '.gh-sb-col[aria-expanded=false]'
  end

  test 'the menus are wired to the menu controller by id' do
    sign_in FactoryBot.create(:user, role: :student)
    get home_path

    # Triggers name their dialog; the controller lives on the shell because the
    # triggers and the dialogs are in different parts of the layout.
    assert_select '.gh-shell[data-controller~=menu]'
    assert_select 'button[data-action~=?][data-menu-id-param=?]', 'menu#open', 'gh-account-menu'
    assert_select 'button[data-action~=?][data-menu-id-param=?]', 'menu#open', 'gh-more-sheet'

    # Scoped, not merely present. A Stimulus action only reaches a controller on
    # an ancestor, and these dialogs originally rendered as SIBLINGS of the
    # shell: the markup looked right and every control inside them was dead.
    assert_select '.gh-shell dialog#gh-account-menu'
    assert_select '.gh-shell dialog#gh-more-sheet'
    assert_select '.gh-shell dialog#gh-more-sheet button[data-action~=?]', 'menu#close'
  end

  test 'both theme toggles are labelled and share one controller' do
    sign_in FactoryBot.create(:user, role: :student)
    get home_path

    assert_select '.gh-shell[data-controller~=theme]'
    # Header toggle ships both glyphs; CSS decides which shows, because with no
    # cookie the server cannot know how prefers-color-scheme resolves.
    assert_select '.gh-hd-theme i.gh-ic-moon'
    assert_select '.gh-hd-theme i.gh-ic-sun'

    # Both label targets AND both toggle buttons must sit inside the controller
    # element — the descendant selector is the whole point of this assertion.
    assert_select '.gh-shell [data-theme-target=label]', 2, 'Ciemny motyw'
    assert_select '.gh-shell dialog button[data-action~=?]', 'theme#toggle', 2

    cookies[:gh_theme] = 'dark'
    get home_path
    assert_select '.gh-shell [data-theme-target=label]', 2, 'Jasny motyw'
  end

  test 'entries with no screen behind them yet are inert buttons, never links' do
    sign_in FactoryBot.create(:user, role: :student)
    get home_path

    assert_select 'dialog#gh-account-menu button[type=button]', /Ustawienia konta/
    assert_select 'dialog#gh-more-sheet button[type=button]', /Ustawienia konta/
    assert_select 'dialog a[href="#"]', false
    assert_select 'dialog a:not([href])', false
  end

  test 'a student header offers joining and no bell' do
    sign_in FactoryBot.create(:user, role: :student)
    get home_path

    assert_select '.gh-hd .gh-hd-join', 1
    assert_select '.gh-hd i.fa-bell', false
  end

  test 'a teacher header offers the bell and no join button' do
    sign_in FactoryBot.create(:user, role: :teacher)
    get home_path

    assert_select '.gh-hd i.fa-bell'
    # "Dołącz do grupy" is a student affordance, mirroring the mockup.
    assert_select '.gh-hd .gh-hd-join', false
  end

  test 'the unread count renders in its own container, not the Bootstrap one' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = FactoryBot.create(:story_group, owner: teacher)
    student = FactoryBot.create(:story_group_student, story_group: story_group,
                                                      user:        FactoryBot.create(:user, role: :student),)
    FactoryBot.create_list(:notification, 2, user: teacher, story_group: story_group,
                                             story_group_student: student,)

    sign_in teacher
    get home_path

    assert_select '#gh-notification-dot .gh-count', '2'
    # The legacy container would be filled by a broadcast carrying Bootstrap
    # markup, which would render unstyled here.
    assert_select '#notification-dot-container', false
  end

  # --- student start --------------------------------------------------------

  test 'a student sees a card per group with balance, lives, rank and badges' do
    student = FactoryBot.create(:user, role: :student)
    story_group = FactoryBot.create(:story_group, name: 'Kosmiczne króliki', currency_name: 'Marchewka')
    FactoryBot.create(:rank, story_group: story_group, name: 'Brąz', required_currency_value: 10)
    FactoryBot.create(:rank, story_group: story_group, name: 'Złoto', required_currency_value: 100)
    FactoryBot.create_list(:badge, 3, story_group: story_group)
    membership = FactoryBot.create(:story_group_student, story_group: story_group, user: student,
                                                         lives: 2, current_currency: 30, total_currency: 40,)
    FactoryBot.create(:students_badge, story_group_student: membership,
                                       badge:               story_group.badges.first,)

    sign_in student
    get home_path

    assert_response :success
    assert_select 'h1.gh-h1', 'Cześć, Jan'
    assert_select 'p.gh-lead', /Należysz do 1 grupy/
    assert_select 'article.gh-card.gh-card--neutral.gh-gcard', 1
    assert_select '.gh-card-name', 'Kosmiczne króliki'

    assert_select '.gh-gstat' do
      assert_select 'dd', /30/           # spendable
      assert_select '.gh-lv', /2/        # lives, one heart + a number
      assert_select 'dt b', 'Brąz'       # current rank
      assert_select '.gh-rank-to', '40 z 100 do rangi Złoto'
      assert_select 'dd small', 'z 3'    # badges earned of total
    end

    # The bar reports real numbers to assistive tech, not just a width.
    assert_select '.gh-bar[role=progressbar][aria-valuenow=?][aria-valuemax=?]', '40', '100'
    assert_select '.gh-card-foot a[href=?]', story_group_path(story_group), 'Otwórz grupę'
    assert_select '.gh-card-foot a[href=?]', story_group_shop_index_path(story_group)
  end

  test 'a maxed-out student gets a full bar and different copy, not an empty one' do
    student = FactoryBot.create(:user, role: :student)
    story_group = FactoryBot.create(:story_group)
    FactoryBot.create(:rank, story_group: story_group, name: 'Złoto', required_currency_value: 10)
    FactoryBot.create(:story_group_student, story_group: story_group, user: student, total_currency: 50)

    sign_in student
    get home_path

    assert_select '.gh-rank-to', '50 zebranych. To najwyższa ranga.'
    assert_select '.gh-bar > i[style*="--gh-p: 100%"]'
  end

  test 'a freshly joined group explains itself instead of showing a bare zero' do
    student = FactoryBot.create(:user, role: :student)
    story_group = FactoryBot.create(:story_group, currency_name: 'Marchewki')
    FactoryBot.create(:story_group_student, story_group: story_group, user: student,
                                            current_currency: 0, total_currency: 0,)

    sign_in student
    get home_path

    assert_select 'p.gh-expl', /Dopiero zaczynasz\. Pierwsze Marchewki zdobędziesz na zajęciach\./
  end

  test 'a student in no groups gets an empty state and can still join' do
    sign_in FactoryBot.create(:user, role: :student)
    get home_path

    assert_response :success
    assert_select 'article.gh-gcard', false
    assert_select 'p.gh-lead', /Nie należysz jeszcze do żadnej grupy/
    # The join panel is always there — it is the way out of the empty state.
    assert_select '.gh-joinc a[href=?]', new_join_path, /Dołącz do grupy/
  end

  test 'the feed merges currency movements from every group, newest first' do
    student = FactoryBot.create(:user, role: :student)
    first = FactoryBot.create(:story_group, name: 'Alfa')
    second = FactoryBot.create(:story_group, name: 'Beta')
    in_first = FactoryBot.create(:story_group_student, story_group: first, user: student)
    in_second = FactoryBot.create(:story_group_student, story_group: second, user: student)
    item = FactoryBot.create(:item, story_group: second, name: 'Poprawa wejściówki')

    FactoryBot.create(:activity_group_category,
                      activity_group:    FactoryBot.create(:activity_group, story_group: first),
                      story_description: 'Obecność na zajęciach',).tap do |category|
      CurrencyTransaction.create!(student: in_first, amount: 3, kind: :reward, transactionable: category,
                                  created_at: 2.minutes.ago,)
    end
    CurrencyTransaction.create!(student: in_second, amount: -15, kind: :purchase, transactionable: item,
                                created_at: 1.minute.ago,)

    sign_in student
    get home_path

    assert_select '.gh-feed h2', 'Ostatnio we wszystkich grupach'
    assert_select '.gh-led .gh-led-r', 2
    assert_select '.gh-led .gh-led-r:first-of-type' do
      assert_select '.gh-led-t', /Zakup: Poprawa wejściówki/
      assert_select '.gh-led-t small', /Beta/
      assert_select '.gh-led-a.gh-led-a--spend', '-15'
    end
    assert_select '.gh-led .gh-led-r:last-of-type' do
      assert_select '.gh-led-t', /Obecność na zajęciach/
      assert_select '.gh-led-a.gh-led-a--earn', '+3'
    end
  end

  # --- teacher start --------------------------------------------------------

  test 'a teacher sees purchases bucketed by day, newest bucket first' do
    teacher, story_group, membership = teacher_with_group
    item = FactoryBot.create(:item, story_group: story_group, name: 'Poprawa')

    CurrencyTransaction.create!(student: membership, amount: -12, kind: :purchase,
                                transactionable: item, created_at: 1.hour.ago,)
    CurrencyTransaction.create!(student: membership, amount: -5, kind: :purchase,
                                transactionable: item, created_at: 1.day.ago,)
    CurrencyTransaction.create!(student: membership, amount: -7, kind: :purchase,
                                transactionable: item, created_at: 5.days.ago,)

    sign_in teacher
    get home_path

    assert_response :success
    assert_select 'h1.gh-h1', 'Dzień dobry, Jan'
    assert_select 'p.gh-lead', /Od wczoraj studenci kupili 2 przedmioty w 1 grupie/
    assert_select 'h3.gh-day', 3
    assert_equal %w[Dziś Wczoraj Wcześniej],
                 css_select('h3.gh-day').map(&:text)
    assert_select '.gh-plist .gh-prow', 3
    assert_select '.gh-prow .gh-cost b', '12'
  end

  test 'a reward never shows up in the purchases list' do
    teacher, story_group, membership = teacher_with_group
    category = FactoryBot.create(:activity_group_category,
                                 activity_group: FactoryBot.create(:activity_group, story_group: story_group),)
    CurrencyTransaction.create!(student: membership, amount: 10, kind: :reward, transactionable: category)

    sign_in teacher
    get home_path

    assert_select '.gh-prow', false
    assert_select '.gh-purch p.gh-small', /Nikt jeszcze niczego nie kupił/
  end

  test 'the group filter is a link, so the choice survives a refresh' do
    teacher, first, membership = teacher_with_group
    second = FactoryBot.create(:story_group, owner: teacher, name: 'Beta')
    other = FactoryBot.create(:story_group_student, story_group: second,
                                                    user:        FactoryBot.create(:user, role: :student),)
    CurrencyTransaction.create!(student: membership, amount: -12, kind: :purchase,
                                transactionable: FactoryBot.create(:item, story_group: first),)
    CurrencyTransaction.create!(student: other, amount: -30, kind: :purchase,
                                transactionable: FactoryBot.create(:item, story_group: second),)

    sign_in teacher
    get home_path
    assert_select '.gh-prow', 2
    assert_select 'a.gh-fchip[href=?][aria-current=true]', home_path, 'Wszystkie grupy'

    get home_path(group: second.id)
    assert_select '.gh-prow', 1
    assert_select '.gh-prow .gh-cost b', '30'
    assert_select 'a.gh-fchip[href=?][aria-current=true]', home_path(group: second.id)
    # The greeting describes the teacher's whole world, not the filter.
    assert_select 'p.gh-lead', /kupili 2 przedmioty w 2 grupach/
  end

  test 'the grading card names a sheet that really has unawarded categories' do
    teacher, story_group, membership = teacher_with_group
    activity_group = FactoryBot.create(:activity_group, story_group: story_group, name: 'Laboratoria 5')
    awarded = FactoryBot.create(:activity_group_category, activity_group: activity_group, position: 0)
    FactoryBot.create_list(:activity_group_category, 2, activity_group: activity_group, position: 1)
    StudentsActivityGroupCategory.create!(student: membership, activity_group_category: awarded)

    sign_in teacher
    get home_path

    assert_select '.gh-todo .gh-k', 'Czeka na ocenę'
    assert_select '.gh-todo-t', 'Laboratoria 5'
    assert_select '.gh-todo p.gh-small', /Zostało 2 kategorie dla 1 studenta\./
    assert_select '.gh-todo a[href=?]',
                  edit_story_group_activity_group_students_activity_group_categories_path(story_group, activity_group),
                  'Oceń'
  end

  test 'a fully awarded sheet is not called pending' do
    teacher, story_group, membership = teacher_with_group
    activity_group = FactoryBot.create(:activity_group, story_group: story_group)
    category = FactoryBot.create(:activity_group_category, activity_group: activity_group)
    StudentsActivityGroupCategory.create!(student: membership, activity_group_category: category)

    sign_in teacher
    get home_path

    assert_select '.gh-todo', false
  end

  test 'a teacher with no groups is told how to start' do
    sign_in FactoryBot.create(:user, role: :teacher)
    get home_path

    assert_response :success
    assert_select 'p.gh-lead', /Nie prowadzisz jeszcze żadnej grupy/
    assert_select '.gh-mygroups p.gh-small', 'Nie prowadzisz jeszcze żadnej grupy.'
    assert_select '.gh-mygroups a[href=?]', new_story_group_path, /Utwórz grupę/
    # No filter row for a teacher who cannot filter by anything.
    assert_select '.gh-filters', false
  end

  test 'the groups list counts students and flags new purchases' do
    teacher, story_group, membership = teacher_with_group
    CurrencyTransaction.create!(student: membership, amount: -9, kind: :purchase,
                                transactionable: FactoryBot.create(:item, story_group: story_group),)

    sign_in teacher
    get home_path

    assert_select '.gh-gtl .gh-gt' do
      assert_select 'small', 'Prowadzisz, 1 student'
      assert_select '.gh-gt-new', '1 nowy zakup'
    end
  end

  # --- notifications --------------------------------------------------------

  test 'the redesign asks for notifications in the anchored panel frame' do
    teacher, story_group, membership = teacher_with_group
    FactoryBot.create(:notification, user: teacher, story_group: story_group, story_group_student: membership)

    sign_in teacher
    get notifications_path, headers: { 'Turbo-Frame' => 'panel' }

    assert_response :success
    assert_select 'turbo-frame#panel'
    assert_select '.gh-pop-h h2.gh-h3', 'Powiadomienia'
    assert_select 'ul.gh-nlist li.gh-nrow'
    assert_no_match(/data-bs-/, response.body)
  end

  test 'a notification row shows the purchased item, not the group icon' do
    teacher, story_group, membership = teacher_with_group
    item = FactoryBot.create(:item, story_group: story_group, name: 'Poprawa wejściówki')
    FactoryBot.create(:notification, user: teacher, story_group: story_group,
                                     story_group_student: membership, item: item,)

    sign_in teacher
    get notifications_path, headers: { 'Turbo-Frame' => 'panel' }

    assert_select 'li.gh-nrow' do
      # The mockup's miniCard: the ITEM as an orange mini entity card. The group
      # belongs in the caption line, not in the thumbnail.
      assert_select '.gh-mc .gh-card-i'
      assert_select '.gh-gthumb', false
      assert_select '.gh-nrow-t b', membership.full_name
      assert_select '.gh-nrow-t > span', 'Zakup: Poprawa wejściówki'
      assert_select '.gh-nrow-t small', /Alfa, dziś/
    end
  end

  test 'only unread rows carry the dot' do
    teacher, story_group, membership = teacher_with_group
    FactoryBot.create(:notification, user: teacher, story_group: story_group, story_group_student: membership)
    FactoryBot.create(:notification, user: teacher, story_group: story_group,
                                     story_group_student: membership, read_at: 1.hour.ago,)

    sign_in teacher
    get notifications_path, headers: { 'Turbo-Frame' => 'panel' }

    assert_select 'p.gh-pop-sec', 2                      # Nowe + Wcześniej
    assert_select 'li.gh-nrow', 2
    assert_select 'li.gh-nrow--unread', 1
    assert_select 'li.gh-nrow--unread .gh-ndot', 1
    assert_select 'li.gh-nrow:not(.gh-nrow--unread) .gh-ndot', false
  end

  test 'the panel has no close button and no purchases link' do
    teacher, story_group, membership = teacher_with_group
    FactoryBot.create(:notification, user: teacher, story_group: story_group, story_group_student: membership)

    sign_in teacher
    get notifications_path, headers: { 'Turbo-Frame' => 'panel' }

    # Dismissal is clicking away or Escape, as in the mockup's popover.
    assert_select '.gh-close', false
    assert_no_match(/Wszystkie zakupy w grupie/, response.body)
    # Mark-all lives in the header, not in a footer.
    assert_select '.gh-pop-h form[action=?][method=post]', mark_as_read_notifications_path do
      assert_select 'button.gh-linkbtn', /Oznacz wszystkie/
      assert_select 'i.fa-check-double'
    end
  end

  test 'the mark-all button is absent when nothing is unread' do
    teacher, story_group, membership = teacher_with_group
    FactoryBot.create(:notification, user: teacher, story_group: story_group,
                                     story_group_student: membership, read_at: 1.hour.ago,)

    sign_in teacher
    get notifications_path, headers: { 'Turbo-Frame' => 'panel' }

    assert_select '.gh-pop-h h2.gh-h3', 'Powiadomienia'
    assert_select '.gh-pop-h button.gh-linkbtn', false
  end

  test 'both dialogs light-dismiss on a backdrop click' do
    sign_in FactoryBot.create(:user, role: :teacher)
    get home_path

    # A native <dialog> does not close on an outside click by itself, so every
    # dialog has to opt in explicitly or Escape becomes the only way out.
    assert_select 'dialog.gh-dialog--anchored[data-action~=?]', 'click->dialog#closeOnBackdrop'
    assert_select 'dialog.gh-dialog:not(.gh-dialog--anchored)[data-action~=?]',
                  'click->dialog#closeOnBackdrop'
  end

  test 'popovers use the anchored panel and forms the centred modal' do
    teacher = FactoryBot.create(:user, role: :teacher)
    sign_in teacher
    get home_path

    # Notifications are a popover in the mockup — corner-pinned and unscrimmed
    # on desktop — so they must not share the centred modal used by forms.
    assert_select '.gh-hd a[href=?][data-turbo-frame=panel]', notifications_path
    assert_select '.gh-tabbar a[href=?][data-turbo-frame=panel]', notifications_path
    assert_select '.gh-shell dialog.gh-dialog--anchored turbo-frame#panel'

    # Genuine modals keep the centred dialog.
    assert_select 'a[href=?][data-turbo-frame=modal]', new_story_group_path
    assert_select 'dialog.gh-dialog:not(.gh-dialog--anchored) turbo-frame#modal'

    sign_out
    sign_in FactoryBot.create(:user, role: :student)
    get home_path
    assert_select 'a[href=?][data-turbo-frame=modal]', new_join_path
  end

  test 'the unread badge sits in a slot that leaves the button grid flow' do
    sign_in FactoryBot.create(:user, role: :teacher)
    get home_path

    # Without .gh-dot-slot this wrapper is a second in-flow grid item in
    # .gh-iconbtn and shoves the bell glyph out of centre.
    assert_select '.gh-hd .gh-iconbtn #gh-notification-dot.gh-dot-slot'
  end

  test 'marking all read clears the badge in both layouts and refreshes the panel' do
    teacher, story_group, membership = teacher_with_group
    FactoryBot.create(:notification, user: teacher, story_group: story_group, story_group_student: membership)

    sign_in teacher
    post mark_as_read_notifications_path

    assert_response :success
    assert_match(/action="remove" target="notification-dot"/, response.body)
    assert_match(/action="update" target="gh-notification-dot"/, response.body)
    # The panel is open while this runs; without this stream its rows would keep
    # the "Nowe" heading and their unread dots.
    assert_match(/action="update" target="panel"/, response.body)
    assert_no_match(/gh-ndot/, response.body)
    assert_no_match(/Oznacz wszystkie/, response.body)

    get home_path
    assert_select '#gh-notification-dot .gh-count', false
  end

  test 'the badge partial renders outside a controller, as the broadcast needs' do
    # Notification's after_create_commit renders this partial through
    # ApplicationController.render, where no view context and no gh_* helpers
    # are in scope. Rendering it the same way is what catches a partial that
    # only works inside a request.
    html = ApplicationController.render(partial: 'layouts/redesign/notification_dot',
                                        locals:  { count: 3 },)

    assert_match(/id="gh-notification-dot"/, html)
    assert_match(/gh-count/, html)
    assert_match(/>3</, html)

    assert_no_match(/gh-count/, ApplicationController.render(partial: 'layouts/redesign/notification_dot',
                                                             locals:  { count: 0 },),)
  end

  test 'the Bootstrap dropdown still gets its own frame and markup' do
    teacher, story_group, membership = teacher_with_group
    FactoryBot.create(:notification, user: teacher, story_group: story_group, story_group_student: membership)

    sign_in teacher
    get notifications_path, headers: { 'Turbo-Frame' => 'notifications_list' }

    assert_response :success
    assert_select 'turbo-frame#notifications_list'
    assert_select 'turbo-frame#modal', false
  end

  private

  def teacher_with_group
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = FactoryBot.create(:story_group, owner: teacher, name: 'Alfa')
    membership = FactoryBot.create(:story_group_student, story_group: story_group,
                                                         user:        FactoryBot.create(:user, role: :student),)
    [teacher, story_group, membership]
  end
end
