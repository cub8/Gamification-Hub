# frozen_string_literal: true

require 'test_helper'

# The Odznaki screens: the teacher's grid (#/t/badges, js-expanded/30-lists.js:30-33),
# the student's deck of flip cards (#/s/badges, 30-sp.js:25-28) and the form page
# behind both (30-br.js:44-69).
class BadgesRedesignSmokeTest < ActionDispatch::IntegrationTest
  MODAL = { 'Turbo-Frame' => 'modal' }.freeze

  setup do
    @owner = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @owner, name: 'Zakon Algorytmów')
    sign_in @owner
  end

  # sign_in is a no-op while a session is live — the magic-link verify refuses
  # to run for someone already logged in — so switching user needs the sign_out.
  def sign_in_as(user)
    sign_out
    sign_in user
  end

  def badge(
    name:,
    rule: 'Trzy wejściówki z rzędu',
    story: 'Lot bez rysy',
    discount: 3,
    glyph: 'rabbit'
  )
    FactoryBot.create(:badge, story_group: @story_group, name: name,
                              didactic_description: rule, story_description: story,
                              discount: discount, icon_glyph: glyph,)
  end

  # Alphabetical, which is the order both screens read in.
  def shelf!
    @mechanik = badge(name: 'Mechanik Załogi', glyph: 'wrench')
    @pokladzie = badge(name: 'Zawsze na pokładzie', glyph: 'rocket', discount: 0)
    @pilot = badge(name: 'Perfekcyjny Lot', glyph: 'starTrail', discount: 5)
  end

  def join_as_student(badges: [])
    student = FactoryBot.create(:user, role: :student)
    membership = FactoryBot.create(:story_group_student, story_group: @story_group, user: student)
    badges.each { |b| FactoryBot.create(:students_badge, story_group_student: membership, badge: b) }
    sign_in_as student
    membership
  end

  def form_params(
    name: 'Perfekcyjny Lot',
    rule: 'Trzy wejściówki bez błędu',
    story: '',
    discount: 4,
    glyph: 'crown'
  )
    {
      badge: {
        name:                 name,
        didactic_description: rule,
        story_description:    story,
        discount:             discount,
        icon_glyph:           glyph,
      },
    }
  end

  def card_names(selector)
    css_select("#{selector} .gh-card-name").map { |node| node.text.strip }
  end

  # --- the teacher grid -----------------------------------------------------

  test 'the teacher gets a grid of badges with the create action' do
    shelf!

    get story_group_badges_path(@story_group)

    assert_response :success
    assert_select 'h1.gh-h1', 'Odznaki'
    assert_equal ['Mechanik Załogi', 'Perfekcyjny Lot', 'Zawsze na pokładzie'],
                 card_names('.gh-lgrid')
    assert_select '.gh-rowb a[href=?]', new_story_group_badge_path(@story_group), 'Nowa odznaka'
  end

  # Przyznaj happens one student at a time, on the students list — that screen
  # is still on the Bootstrap layout, so this is a plain link out of the deck.
  test 'each card offers Przyznaj and Edytuj' do
    shelf!

    get story_group_badges_path(@story_group)

    assert_select '.gh-card-acts a[href=?]', story_group_students_path(@story_group), 'Przyznaj'
    assert_select '.gh-card-acts a[href=?][aria-label=?]',
                  edit_story_group_badge_path(@story_group, @mechanik),
                  'Edytuj odznakę Mechanik Załogi'
  end

  test 'the lead counts the badges in Polish' do
    shelf!

    get story_group_badges_path(@story_group)

    assert_select '.gh-lead', /\A3 odznaki\./
  end

  # The teacher has no "not earned yet" side to look at, so these are flat
  # cards — the flip belongs to the student's deck only.
  test 'the teacher grid does not flip' do
    shelf!

    get story_group_badges_path(@story_group)

    assert_select '.gh-lgrid .gh-flip', false
    assert_select '.gh-lgrid .gh-face', false
  end

  test 'each card counts who holds it' do
    shelf!
    2.times do
      membership = FactoryBot.create(:story_group_student, story_group: @story_group,
                                                           user:        FactoryBot.create(:user, role: :student),)
      FactoryBot.create(:students_badge, story_group_student: membership, badge: @mechanik)
    end

    get story_group_badges_path(@story_group)

    assert_select '.gh-meta', 'Ma ją 2 studentów'
    assert_select '.gh-meta', 'Nikt jej jeszcze nie ma'
  end

  test 'a badge worth nothing shows no discount tag' do
    shelf!

    get story_group_badges_path(@story_group)

    assert_select '.gh-tag--disc', '−3% w sklepie'
    assert_select '.gh-tag--disc', '−5% w sklepie'
    assert_select '.gh-tag--disc', { text: '−0% w sklepie', count: 0 }
  end

  test 'a group with no badges tells the teacher what to do about it' do
    get story_group_badges_path(@story_group)

    assert_select '.gh-lgrid', false
    assert_select '.gh-gm .gh-h2', 'Nie ma jeszcze żadnych odznak'
  end

  # --- the student deck -----------------------------------------------------

  test 'a student sees earned badges face up and the rest turned over' do
    shelf!
    join_as_student(badges: [@mechanik])

    get story_group_badges_path(@story_group)

    assert_response :success
    assert_select '.gh-lgrid', false
    assert_select '.gh-cards--b .gh-flip', 3
    assert_select '.gh-cards--b .gh-flip--down', 2
    assert_select '.gh-flip:not(.gh-flip--down)[aria-label=?]', 'Odznaka Mechanik Załogi'
    assert_select '.gh-flip--down[aria-label=?]', 'Odznaka Perfekcyjny Lot, jeszcze niezdobyta'
  end

  test 'the lead counts what the student has out of what there is' do
    shelf!
    join_as_student(badges: [@mechanik, @pilot])

    get story_group_badges_path(@story_group)

    assert_select '.gh-lead', /\AMasz 2 z 3\./
  end

  # Every card carries both faces — the rule is on the back of an unearned one,
  # which is the only place a student can read it.
  test 'the back of an unearned badge carries the rule and the house mark' do
    shelf!
    join_as_student

    get story_group_badges_path(@story_group)

    assert_select '.gh-face--back .gh-back-art svg', 3
    assert_select '.gh-face--back .gh-how span', 'Jak zdobyć'
    assert_select '.gh-face--back .gh-how', /Trzy wejściówki z rzędu/
  end

  # The decision: an earned card can be turned over to re-read how it was won;
  # an unearned one cannot, because its art is the reward.
  test 'only an earned card mounts the flip controller' do
    shelf!
    join_as_student(badges: [@mechanik])

    get story_group_badges_path(@story_group)

    assert_select '.gh-flip[data-controller=badge-flip]', 1
    assert_select '.gh-flip--down[data-controller=badge-flip]', false
    assert_select '.gh-flip[data-controller=badge-flip] .gh-flipbtn', 2
    assert_select '.gh-flip--down .gh-flipbtn', false
  end

  # backface-visibility hides the far side from the eye, not from the tab order.
  test 'the turned-away face is inert and aria-hidden' do
    shelf!
    join_as_student(badges: [@mechanik])

    get story_group_badges_path(@story_group)

    assert_select '.gh-flip:not(.gh-flip--down) .gh-face--back[inert][aria-hidden=true]', 1
    assert_select '.gh-flip:not(.gh-flip--down) .gh-face--front[inert]', false
    assert_select '.gh-flip--down .gh-face--front[inert][aria-hidden=true]', 2
  end

  test 'a student in a group with no badges gets their own empty state' do
    join_as_student

    get story_group_badges_path(@story_group)

    assert_select '.gh-gm .gh-h2', 'W tej grupie nie ma jeszcze odznak'
  end

  # --- creating and editing -------------------------------------------------

  test 'the new form is a page and offers the badge presets' do
    get new_story_group_badge_path(@story_group)

    assert_response :success
    assert_select 'header.gh-hd', 1
    assert_select 'main#app-content turbo-frame#modal', false
    assert_select 'h1.gh-h1', 'Nowa odznaka'
    assert_select 'input[name=?][value=?]', 'badge[discount]', '0'
    assert_select '.gh-pz-grid .gh-pz--badge input[type=radio]', Redesign::Glyphs::BADGE.size
    assert_select '.gh-pz--own[hidden]', 1
    assert_select '.gh-pz--own img[src]', false
  end

  test 'the form listens for the crop so the preview can follow it' do
    get new_story_group_badge_path(@story_group)

    assert_select 'form[data-action=?]', 'gh:image-crop->badge-form#art'
    assert_select 'form[data-controller=badge-form]', 1
  end

  # The point of this screen (30-br.js:159): both faces at once, with a control
  # that says which one you are looking at.
  test 'the preview shows both faces and a control to turn between them' do
    get new_story_group_badge_path(@story_group)

    assert_select '.gh-pvflip .gh-face--front', 1
    assert_select '.gh-pvflip .gh-face--back', 1
    assert_select '.gh-seg2 button[aria-pressed=true]', 'Zdobyta'
    assert_select '.gh-seg2 button[aria-pressed=false]', 'Jeszcze niezdobyta'
    # The teacher turns it with the control, never by clicking the card.
    assert_select '.gh-pvflip .gh-flip[data-controller]', false
  end

  test 'the empty preview says what each field will say' do
    get new_story_group_badge_path(@story_group)

    assert_select '.gh-pvflip .gh-face--front .gh-card-name.gh-ph', 'Nazwa odznaki'
    assert_select '.gh-pvflip .gh-face--front .gh-rules.gh-ph', 'Jak zdobyć…'
    assert_select '.gh-pvflip .gh-face--front .gh-flavor[hidden]', 1
    assert_select '.gh-pvflip .gh-tag--disc[hidden]', 1
  end

  test 'creating a badge says so and returns to the list' do
    assert_difference('Badge.count', 1) do
      post story_group_badges_path(@story_group), params: form_params
    end

    assert_redirected_to story_group_badges_path(@story_group)
    assert_equal 'Dodano odznakę „Perfekcyjny Lot”.', flash[:notice]
  end

  test 'a blank name is refused on the field' do
    assert_no_difference('Badge.count') do
      post story_group_badges_path(@story_group), params: form_params(name: '')
    end

    assert_response :unprocessable_content
    assert_select '.gh-inp--bad input[name=?]', 'badge[name]'
    assert_select '#gh-badge-name-error span', 'Podaj nazwę odznaki.'
  end

  # The rule is the only thing on the back of a badge nobody has earned yet.
  test 'a blank rule is refused on the field' do
    assert_no_difference('Badge.count') do
      post story_group_badges_path(@story_group), params: form_params(rule: '')
    end

    assert_response :unprocessable_content
    assert_select '.gh-inp--bad textarea[name=?]', 'badge[didactic_description]'
    assert_select '#gh-badge-rule-error span', 'Napisz, jak zdobyć tę odznakę.'
  end

  test 'a glyph outside the badge presets is refused' do
    assert_no_difference('Badge.count') do
      post story_group_badges_path(@story_group), params: form_params(glyph: 'chev1')
    end

    assert_response :unprocessable_content
  end

  test 'the edit form warns how many students the change reaches' do
    shelf!
    membership = FactoryBot.create(:story_group_student, story_group: @story_group,
                                                         user:        FactoryBot.create(:user, role: :student),)
    FactoryBot.create(:students_badge, story_group_student: membership, badge: @mechanik)

    get edit_story_group_badge_path(@story_group, @mechanik)

    assert_response :success
    assert_select 'h1.gh-h1', 'Edytuj odznakę'
    assert_select '.gh-info b', '1 student ma tę odznakę.'
  end

  test 'the edit form lists the items whose discount counts this badge' do
    shelf!
    FactoryBot.create(:item, story_group: @story_group, name: 'Bezpieczna poprawa',
                             discount_badges: [@mechanik],)

    get edit_story_group_badge_path(@story_group, @mechanik)
    assert_select '.gh-uses li', /Bezpieczna poprawa/

    get edit_story_group_badge_path(@story_group, @pilot)
    assert_select '.gh-uses', false
    assert_select '.gh-expl', 'Na razie żaden przedmiot jej nie uwzględnia.'
  end

  test 'editing a badge keeps the count and says so' do
    shelf!

    assert_no_difference('Badge.count') do
      patch story_group_badge_path(@story_group, @mechanik),
            params: form_params(name: 'Mechanik Floty', glyph: 'wrench')
    end

    assert_redirected_to story_group_badges_path(@story_group)
    assert_equal 'Zapisano odznakę „Mechanik Floty”.', flash[:notice]
  end

  # --- deleting -------------------------------------------------------------

  test 'the confirm dialog spells out what happens to the students who have it' do
    shelf!

    get confirm_destroy_story_group_badge_path(@story_group, @mechanik), headers: MODAL

    assert_response :success
    assert_select 'h2', 'Usunąć odznakę „Mechanik Załogi”?'
    assert_select 'p', /zachowają ją w historii, ale nikt nowy jej nie dostanie/
    assert_select '.gh-warn', false
  end

  # Not a blocker, unlike ranks: a soft delete breaks no foreign key. The button
  # stays enabled and the dialog says what stops being buyable.
  test 'an item that unlocks on the badge is named but does not block' do
    shelf!
    FactoryBot.create(:item, story_group: @story_group, name: '0.5% oceny',
                             unlock_badges: [@mechanik],)

    get confirm_destroy_story_group_badge_path(@story_group, @mechanik), headers: MODAL
    assert_select '.gh-warn span', /Przedmiot 0\.5% oceny odblokowuje się tą odznaką/
    assert_select '.gh-dlg-b button[disabled]', false

    delete story_group_badge_path(@story_group, @mechanik), headers: MODAL
    assert_predicate @mechanik.reload, :deleted?
  end

  # An item whose DISCOUNT counts the badge keeps working — nothing about it
  # breaks — so it is not worth a warning.
  test 'an item that only discounts on the badge raises no warning' do
    shelf!
    FactoryBot.create(:item, story_group: @story_group, name: 'Bezpieczna poprawa',
                             discount_badges: [@mechanik],)

    get confirm_destroy_story_group_badge_path(@story_group, @mechanik), headers: MODAL

    assert_select '.gh-warn', false
  end

  test 'deleting takes the badge off every list but leaves it on the deck that earned it' do
    shelf!
    student = FactoryBot.create(:user, role: :student)
    membership = FactoryBot.create(:story_group_student, story_group: @story_group, user: student)
    FactoryBot.create(:students_badge, story_group_student: membership, badge: @mechanik)

    assert_no_difference('Badge.count') do
      delete story_group_badge_path(@story_group, @mechanik), headers: MODAL
    end

    assert_turbo_redirected_to story_group_badges_url(@story_group)
    assert_match(/Usunięto odznakę „Mechanik Załogi”/, flash[:notice])

    get story_group_badges_path(@story_group)
    assert_equal ['Perfekcyjny Lot', 'Zawsze na pokładzie'], card_names('.gh-lgrid')

    # It is gone from the award picker too.
    get new_story_group_student_badge_path(@story_group, membership)
    assert_select 'option[value=?]', @mechanik.id.to_s, false

    sign_in_as student
    get story_group_badges_path(@story_group)
    # Two live badges plus the one they earned, which is now history.
    assert_select '.gh-cards--b .gh-flip', 3
    assert_select '.gh-tag--del', 'Usunięta z listy'
    assert_select '.gh-lead', /\AMasz 0 z 2\./
  end

  test 'a deleted badge has no edit page of its own' do
    shelf!
    @mechanik.soft_delete!

    # ApplicationController turns the RecordNotFound into the app's own
    # "Nie znaleziono." rather than a bare 404.
    get edit_story_group_badge_path(@story_group, @mechanik)

    assert_redirected_to root_path
  end

  # --- art ------------------------------------------------------------------

  test 'a preset is inlined so it can take the card colour' do
    shelf!

    get story_group_badges_path(@story_group)

    # Inline SVG, not <img>: .gh-gph strokes in currentColor, which is what
    # makes the same shape teal here and gold on a rank.
    assert_select '.gh-lgrid .gh-art svg.gh-gph', 3
    assert_select '.gh-lgrid .gh-art img', false
  end

  # Neither a preset nor an upload. Art is required of new badges now, so this
  # can only be a row saved before that rule existed — which still has to
  # render rather than blow up the list.
  test 'a badge with no art at all falls back to an icon' do
    badge(name: 'Bez grafiki').update_column(:icon_glyph, nil)

    get story_group_badges_path(@story_group)

    assert_select '.gh-lgrid .gh-art i.fa-award', 1
  end

  test 'an uploaded icon becomes the art and the picker agrees' do
    shelf!
    @mechanik.icon.attach(io: Rails.root.join('test/fixtures/files/rank_art.png').open,
                          filename: 'rank_art.png', content_type: 'image/png',)
    @mechanik.update!(icon_glyph: nil)

    get story_group_badges_path(@story_group)
    assert_select ".gh-lgrid img[alt='']", 1

    get edit_story_group_badge_path(@story_group, @mechanik)
    assert_select '.gh-pz--own[hidden]', false
    assert_select '.gh-pz--own input[checked=checked]', 1
  end

  # Without JavaScript nothing would ever select the upload: the picker's own
  # tile is hidden until there is something attached.
  test 'uploading a file wins over whatever preset was selected' do
    shelf!

    patch story_group_badge_path(@story_group, @mechanik),
          params: form_params(name: @mechanik.name, glyph: 'crown')
                  .deep_merge(badge: { icon: fixture_file_upload('rank_art.png', 'image/png') })

    assert_redirected_to story_group_badges_path(@story_group)
    assert_nil @mechanik.reload.icon_glyph
    assert_equal :upload, @mechanik.art
  end

  # --- presentation ---------------------------------------------------------

  test 'the confirm dialog carries one modal frame, and none as a page' do
    shelf!
    path = confirm_destroy_story_group_badge_path(@story_group, @mechanik)

    get path, headers: MODAL
    assert_select 'turbo-frame#modal', 1

    get path
    assert_select 'main#app-content turbo-frame#modal', false
    assert_select 'main .gh-panel.gh-dlg-page', 1
    assert_select 'header.gh-hd', 1
  end

  test 'creating says so in a toast, not in a banner' do
    post story_group_badges_path(@story_group), params: form_params

    get story_group_badges_path(@story_group)

    assert_select '#gh-toasts template[data-toast-target=seed]', 'Dodano odznakę „Perfekcyjny Lot”.'
    assert_select '#flash-messages', false
  end

  # The mockup has no badge detail: the card IS the detail and editing is a page.
  test 'there is no badge detail screen' do
    shelf!

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path(
        "/story_groups/#{@story_group.id}/badges/#{@mechanik.id}", method: :get,
      )
    end
  end

  # --- authorization --------------------------------------------------------

  test 'a student cannot open the form or write' do
    shelf!
    join_as_student

    get new_story_group_badge_path(@story_group)
    assert_redirected_to root_path

    post story_group_badges_path(@story_group), params: form_params
    assert_redirected_to root_path

    delete story_group_badge_path(@story_group, @mechanik)
    assert_redirected_to root_path
  end

  test 'a supporting teacher may manage badges' do
    supporter = FactoryBot.create(:user, role: :teacher)
    FactoryBot.create(:story_group_teacher, story_group: @story_group, user: supporter)
    sign_in_as supporter

    get new_story_group_badge_path(@story_group)

    assert_response :success
  end
end
