# frozen_string_literal: true

require 'test_helper'

# The Przedmioty screens: the teacher's price list (#/t/items,
# js-expanded/30-lists.js:34-37) and the form page behind it
# (js-expanded/30-item.js).
#
# Teacher only — a student meets items in the shop and in their inventory, both
# of which are still on the Bootstrap layout.
class ItemsRedesignSmokeTest < ActionDispatch::IntegrationTest
  MODAL = { 'Turbo-Frame' => 'modal' }.freeze

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

  def item(name:, price: 20, **attributes)
    FactoryBot.create(:item, story_group: @story_group, name: name, price: price, **attributes)
  end

  # Deliberately created out of price order: the screen sorts, the factory does
  # not.
  def shop!
    @konsultacja = item(name: 'Konsultacja', price: 30)
    @poprawa     = item(name: 'Poprawa wejściówki', price: 10)
    @oneup       = item(name: 'Dodatkowe życie', price: 20, can_buy_at_0_lives: true)
  end

  # The discount box holds two sentences now, so an assertion has to name the
  # one it means rather than the box.
  EXAMPLE = '[data-item-form-target=discountText]'
  MAXIMUM = '[data-item-form-target=discountMax]'
  UNLOCK  = '[data-item-form-target=unlockText]'

  def rank(name:, threshold:, discount: 0)
    FactoryBot.create(:rank, story_group: @story_group, name: name,
                             required_currency_value: threshold, discount: discount,)
  end

  def badge(name:, discount: 0)
    FactoryBot.create(:badge, story_group: @story_group, name: name, discount: discount)
  end

  def form_params(name: 'Poprawa wejściówki', rules: 'Możliwość ponownego napisania', **overrides)
    {
      item: {
        name:                 name,
        didactic_description: rules,
        story_description:    '',
        price:                12,
        icon_glyph:           'retake',
      }.merge(overrides),
    }
  end

  def card_names(selector)
    css_select("#{selector} .gh-card-name").map { |node| node.text.strip }
  end

  # --- the teacher list -----------------------------------------------------

  test 'the teacher gets a price list with the create action' do
    shop!

    get story_group_items_path(@story_group)

    assert_response :success
    assert_select 'h1.gh-h1', 'Przedmioty'
    assert_equal ['Poprawa wejściówki', 'Dodatkowe życie', 'Konsultacja'], card_names('.gh-lgrid')
    assert_select '.gh-rowb a[href=?]', new_story_group_item_path(@story_group), 'Nowy przedmiot'
  end

  test 'the lead counts the items in Polish' do
    shop!

    get story_group_items_path(@story_group)

    assert_select '.gh-lead', /\A3 przedmioty w sklepie,/
  end

  test 'each card links to its own edit page' do
    shop!

    get story_group_items_path(@story_group)

    assert_select '.gh-card-acts a[href=?][aria-label=?]',
                  edit_story_group_item_path(@story_group, @poprawa),
                  'Edytuj przedmiot Poprawa wejściówki'
  end

  test 'each card counts how many times it was bought' do
    shop!
    2.times do
      membership = FactoryBot.create(:story_group_student, story_group: @story_group,
                                                           user:        FactoryBot.create(:user, role: :student),)
      FactoryBot.create(:students_item, story_group_student: membership, item: @poprawa)
    end

    get story_group_items_path(@story_group)

    assert_select '.gh-meta', 'Kupiono 2 razy'
    assert_select '.gh-meta', 'Jeszcze nikt nie kupił'
  end

  # Requirements read as locks on this screen, and the discount is a flag rather
  # than a number: the list is about what an item IS, not what any one student
  # would pay for it.
  test 'requirements and exceptions show as tags' do
    shop!
    kapitan = rank(name: 'Kapitan', threshold: 100)
    nawigator = badge(name: 'Nawigator', discount: 10)
    @konsultacja.update!(unlock_rank: kapitan)
    @poprawa.discount_badges << nawigator

    get story_group_items_path(@story_group)

    assert_select '.gh-tag--lock', 'Od rangi Kapitan'
    assert_select '.gh-tag--disc', 'Zniżka'
    assert_select '.gh-tag--life', 'Przy 0 życiach'
  end

  test 'a group with no items tells the teacher what to do about it' do
    get story_group_items_path(@story_group)

    assert_select '.gh-lgrid', false
    assert_select '.gh-gm .gh-h2', 'Sklep jest jeszcze pusty'
  end

  # --- the form -------------------------------------------------------------

  test 'the new form is a page, not a modal, and seeds a price' do
    get new_story_group_item_path(@story_group)

    assert_response :success
    assert_select 'h1.gh-h1', 'Nowy przedmiot'
    assert_select 'main#app-content turbo-frame#modal', false
    assert_select 'input[name=?][value=?]', 'item[price]', '15'
    assert_select 'form[data-action=?]', 'gh:image-crop->item-form#art'
  end

  test 'the picker offers exactly the item presets, as radios' do
    get new_story_group_item_path(@story_group)

    assert_select '.gh-pz-grid .gh-pz--item input[type=radio]', Redesign::Glyphs::ITEM.size
    assert_select 'input[name=?][value=?][checked=checked]', 'item[icon_glyph]', 'shield'
  end

  test 'creating an item lands back on the list with a toast' do
    assert_difference -> { Item.count }, 1 do
      post story_group_items_path(@story_group), params: form_params
    end

    assert_redirected_to story_group_items_path(@story_group)
    follow_redirect!
    assert_select '#gh-toasts template[data-toast-target=seed]',
                  'Dodano przedmiot „Poprawa wejściówki” do sklepu.'
    assert_select '.gh-flash', false
  end

  test 'an item with no name and no rule comes back with both errors' do
    post story_group_items_path(@story_group), params: form_params(name: '', rules: '')

    assert_response :unprocessable_content
    assert_select '.gh-err[role=alert]', 2
    assert_select '.gh-inp--bad input[aria-invalid=true]'
  end

  test 'the price floor is 1' do
    post story_group_items_path(@story_group), params: form_params(price: 0)

    assert_response :unprocessable_content
    assert_select '.gh-err[role=alert] span', 'Cena musi wynosić co najmniej 1.'
  end

  test 'editing an item saves and says the change is not retroactive' do
    shop!

    patch story_group_item_path(@story_group, @poprawa),
          params: form_params(name: 'Bezpieczna poprawa')

    assert_redirected_to story_group_items_path(@story_group)
    assert_equal 'Bezpieczna poprawa', @poprawa.reload.name
    follow_redirect!
    assert_select '#gh-toasts template[data-toast-target=seed]',
                  'Zapisano „Bezpieczna poprawa”. Zmiany dotyczą nowych zakupów.'
  end

  test 'the edit form warns when students already own the item' do
    shop!
    membership = FactoryBot.create(:story_group_student, story_group: @story_group,
                                                         user:        FactoryBot.create(:user, role: :student),)
    FactoryBot.create(:students_item, story_group_student: membership, item: @poprawa)

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select '.gh-info', /1 student ma ten przedmiot\./
  end

  # --- the chip multiselect -------------------------------------------------

  test 'every badge gets a chip with a real checkbox, checked ones included' do
    shop!
    nawigator = badge(name: 'Nawigator', discount: 10)
    badge(name: 'Mechanik', discount: 5)
    @poprawa.unlock_badges << nawigator

    get edit_story_group_item_path(@story_group, @poprawa)

    # Two badges, two pickers: required-to-buy and discount-giving.
    assert_select '.gh-chips', 2
    assert_select 'input[type=checkbox][name=?]', 'item[unlock_badge_ids][]', 2
    assert_select 'input[type=checkbox][name=?][value=?][checked=checked]',
                  'item[unlock_badge_ids][]', nawigator.id.to_s
    # Clearing every chip has to post something, or the ids would keep their old
    # value on update.
    assert_select 'input[type=hidden][name=?][value=?]', 'item[unlock_badge_ids][]', ''
  end

  test 'clearing every chip clears the badges' do
    shop!
    nawigator = badge(name: 'Nawigator')
    @poprawa.unlock_badges << nawigator

    patch story_group_item_path(@story_group, @poprawa),
          params: form_params(unlock_badge_ids: [''])

    assert_empty @poprawa.reload.unlock_badges
  end

  test 'the adder select starts hidden and carries every badge' do
    shop!
    badge(name: 'Nawigator')
    badge(name: 'Mechanik')

    get edit_story_group_item_path(@story_group, @poprawa)

    # Hidden until chip_picker_controller connects: with JavaScript off the
    # chips themselves are the control and the select would be dead weight.
    assert_select '.gh-chips .gh-sel[hidden]', 2
    assert_select '.gh-chips .gh-sel select option', 6 # 2 placeholders + 2 badges each
  end

  test 'a group with no badges says so instead of showing an empty picker' do
    shop!

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select '.gh-chips', false
    assert_select '.gh-sent .gh-hint', { text: 'W tej grupie nie ma jeszcze odznak.', count: 2 }
  end

  # --- the preview ----------------------------------------------------------

  test 'all three feet are rendered and only the current one is visible' do
    get new_story_group_item_path(@story_group)

    assert_select '.gh-pvcard .gh-foot'
    assert_select '.gh-pvcard .gh-need[hidden]'
    assert_select '.gh-pvcard .gh-req[hidden]'
    assert_select '.gh-pvcard .gh-foot[hidden]', false
  end

  # DECISIONS.md:34 — an item without requirements can never be sealed.
  test 'the sealed tab is disabled until the item has a requirement' do
    get new_story_group_item_path(@story_group)

    assert_select '.gh-seg2 button[value=sealed][disabled]'
    assert_select '.gh-hint', 'Bez wymagań przedmiot nigdy nie będzie zapieczętowany.'
  end

  test 'the sealed tab opens once something gates the item' do
    shop!
    @poprawa.update!(unlock_rank: rank(name: 'Kapitan', threshold: 100))

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select '.gh-seg2 button[value=sealed][disabled]', false
    assert_select '.gh-seal span', 'Od rangi Kapitan'
    assert_select '.gh-req li b', 'Kapitan'
  end

  test 'the preview names the ceiling a student could reach' do
    shop!
    kapitan = rank(name: 'Kapitan', threshold: 100, discount: 15)
    @poprawa.update!(min_rank_for_discount: kapitan)
    @poprawa.discount_badges << badge(name: 'Nawigator', discount: 10)

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select '.gh-tag--disc', 'Zniżki do −25%'
  end

  # Discount::CAP_VALUE is what the shop actually charges; a card promising more
  # would be a lie told by the design.
  test 'the discount ceiling is capped where the till caps it' do
    shop!
    kapitan = rank(name: 'Kapitan', threshold: 100, discount: 40)
    @poprawa.update!(min_rank_for_discount: kapitan)
    @poprawa.discount_badges << badge(name: 'Nawigator', discount: 30)

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select '.gh-tag--disc', "Zniżki do −#{Discount::CAP_VALUE}%"
  end

  test 'an item with no discounts hides the tag rather than promising nothing' do
    shop!

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select '.gh-pvcard .gh-tag--disc[hidden]'
    assert_select EXAMPLE, /\ABez zniżek\./
  end

  test 'the unlock sentence names the rank and the badge' do
    shop!
    @poprawa.update!(unlock_rank: rank(name: 'Kapitan', threshold: 100))
    @poprawa.unlock_badges << badge(name: 'Nawigator')

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select UNLOCK, /Kupią tylko studenci z rangą Kapitan lub wyższą/
    assert_select UNLOCK, /którzy mają odznakę Nawigator, jeśli mają co najmniej 1 życie\./
  end

  test 'a badge that both gates and discounts gets a note, not an error' do
    shop!
    nawigator = badge(name: 'Nawigator', discount: 10)
    @poprawa.unlock_badges << nawigator
    @poprawa.discount_badges << nawigator

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select '.gh-warn2 span',
                  'Odznaka Nawigator jest wymagana do zakupu, więc jej zniżka obejmie każdego kupującego.'
    assert_select '.gh-err', false
  end

  # item_form_controller rewrites this sentence as you type, so the two build
  # it independently. This pins the server's wording; the browser pass pins the
  # client's against it.
  #
  # An EXAMPLE rather than a superlative: a discount needs only ONE condition
  # met (DECISIONS.md:33), so "najwięcej zaoszczędzi…" would read as though all
  # of them were required.
  test 'the discount line reads as an example, naming the saving and the price' do
    shop!
    @poprawa.update!(price: 30)
    @poprawa.discount_badges << badge(name: 'Mechanik Załogi', discount: 5)

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select EXAMPLE,
                  'Przykładowo: student z odznaką Mechanik Załogi zaoszczędzi 5% i zapłaci 29 zamiast 30.'
    assert_select '.gh-hint', /Wystarczy spełnić jeden z warunków/
  end

  test 'the example joins a rank and badges with oraz' do
    shop!
    @poprawa.update!(price: 100, min_rank_for_discount: rank(name: 'Kapitan', threshold: 100, discount: 15))
    @poprawa.discount_badges << badge(name: 'Nawigator', discount: 10)
    @poprawa.discount_badges << badge(name: 'Mechanik', discount: 5)

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select EXAMPLE,
                  'Przykładowo: student z rangą Kapitan oraz odznakami Mechanik i Nawigator ' \
                  'zaoszczędzi 30% i zapłaci 70 zamiast 100.'
  end

  # --- the ceiling mirrors the till, not the item's configuration ----------
  #
  # DiscountCalculatorService is more generous than an item's own settings look:
  # an item naming no discount conditions discounts for EVERYONE, and the amount
  # is the student's rank plus every badge they hold, listed here or not. These
  # five pin the places the old, narrower reading was wrong.

  test 'an item with no discount conditions still promises what the till will give' do
    shop!
    @poprawa.update!(price: 10)
    rank(name: 'Kapitan', threshold: 100, discount: 15)
    badge(name: 'Nawigator', discount: 10)

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select '.gh-pvcard .gh-tag--disc[hidden]', false
    assert_select '.gh-tag--disc', 'Zniżki do −25%'
    assert_select EXAMPLE,
                  'Przykładowo: student z rangą Kapitan oraz odznaką Nawigator ' \
                  'zaoszczędzi 25% i zapłaci 8 zamiast 10.'
  end

  test 'a badge the item does not list still counts toward the ceiling' do
    shop!
    @poprawa.update!(price: 100)
    @poprawa.discount_badges << badge(name: 'Mechanik', discount: 5)
    badge(name: 'Nawigator', discount: 10)

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select '.gh-tag--disc', 'Zniżki do −15%'
    assert_select EXAMPLE,
                  'Przykładowo: student z odznakami Mechanik i Nawigator ' \
                  'zaoszczędzi 15% i zapłaci 85 zamiast 100.'
  end

  # Holding a listed badge qualifies a student of ANY rank, so their own rank's
  # discount rides along even though the item sets no floor.
  test 'discount badges with no floor still reach the whole ladder' do
    shop!
    @poprawa.update!(price: 100)
    rank(name: 'Kapitan', threshold: 100, discount: 15)
    @poprawa.discount_badges << badge(name: 'Nawigator', discount: 10)

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select '.gh-tag--disc', 'Zniżki do −25%'
  end

  # The one configuration that DOES narrow the ladder: a floor with nothing
  # beside it, where being at or above it is the only way in. Add a discount
  # badge and the rungs below the floor come back into reach.
  test 'a floor standing alone keeps the rungs below it out of the ceiling' do
    shop!
    @poprawa.update!(price: 100)
    rank(name: 'Rekrut', threshold: 0, discount: 30)
    kapitan = rank(name: 'Kapitan', threshold: 100, discount: 10)
    @poprawa.update!(min_rank_for_discount: kapitan)

    get edit_story_group_item_path(@story_group, @poprawa)
    assert_select '.gh-tag--disc', 'Zniżki do −10%'

    @poprawa.discount_badges << badge(name: 'Nawigator', discount: 10)

    get edit_story_group_item_path(@story_group, @poprawa)
    assert_select '.gh-tag--disc', 'Zniżki do −40%'
  end

  # "Does anybody pay less than the price on this card", not "did the teacher
  # configure a discount" — a dark flag on an item selling below list price is
  # the same lie in a smaller place.
  test 'the grid flags a discount on an item that names no discount conditions' do
    shop!
    badge(name: 'Nawigator', discount: 10)

    get story_group_items_path(@story_group)

    assert_select '.gh-lgrid .gh-tag--disc', 3
  end

  # The ceiling's group-wide half crosses into TypeScript, so the form hands it
  # over rather than letting the preview re-derive it. These four attributes are
  # the whole of that contract.
  test 'the form hands the preview the same group facts Redesign::ItemCard uses' do
    shop!
    rank(name: 'Rekrut', threshold: 0, discount: 5)
    rank(name: 'Kapitan', threshold: 100, discount: 15)
    badge(name: 'Nawigator', discount: 10)
    badge(name: 'Mechanik', discount: 5)
    badge(name: 'Bez zniżki', discount: 0)

    get edit_story_group_item_path(@story_group, @poprawa)

    form = css_select('form[data-controller=item-form]').first
    card = Redesign::ItemCard.new(@poprawa.reload,
                                  ranks:  @story_group.ranks.by_threshold.to_a,
                                  badges: @story_group.badges.kept.by_name.to_a,)

    assert_equal card.ladder_discount.to_s,   form['data-item-form-ladder-discount-value']
    assert_equal 'Kapitan',                   form['data-item-form-ladder-rank-value']
    assert_equal card.badges_discount.to_s,   form['data-item-form-badge-discount-value']
    # Only the badges that actually add something, in gh_and_list order.
    assert_equal '["Mechanik","Nawigator"]',  form['data-item-form-badge-names-value']
  end

  # --- the example student, the maximum, and the cap --------------------------

  test 'the maximum line spells out the ceiling under the example' do
    shop!
    @poprawa.update!(price: 100)
    rank(name: 'Kapitan', threshold: 100, discount: 15)
    badge(name: 'Nawigator', discount: 10)

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select MAXIMUM, 'Maksymalnie: student z rangą Kapitan oraz odznaką Nawigator uzyska zniżkę 25%.'
  end

  # Naming every badge is exactly what the example above exists to avoid.
  test 'the maximum summarises the badges instead of listing them' do
    shop!
    rank(name: 'Kapitan', threshold: 100, discount: 15)
    %w[Alfa Beta Gamma].each { |name| badge(name: name, discount: 5) }

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select MAXIMUM,
                  'Maksymalnie: student z rangą Kapitan oraz wszystkimi odznakami uzyska zniżkę 30%.'
  end

  # Randomised, so this pins the rule rather than one pick: at most two badges,
  # and the saving it quotes is the sum of exactly what it named.
  test 'the example names at most two badges and its saving matches them' do
    shop!
    @poprawa.update!(price: 100)
    rank(name: 'Kapitan', threshold: 100, discount: 15)
    discounts = { 'Alfa' => 3, 'Beta' => 4, 'Gamma' => 5, 'Delta' => 6, 'Epsilon' => 7 }
    discounts.each { |name, value| badge(name: name, discount: value) }

    5.times do
      get edit_story_group_item_path(@story_group, @poprawa)

      bolds = css_select("#{EXAMPLE} b").map { |bold| bold.text.strip }

      assert_equal 'Kapitan', bolds.first

      named = bolds.second.split(/,\s*|\s+i\s+/)
      assert_operator named.size, :<=, Redesign::DiscountExample::MAX_BADGES
      expected = named.sum { |name| discounts[name] } + 15

      assert_equal expected, bolds.third.delete('%').to_i
    end
  end

  # A rung below the floor qualifies for nothing, so the example must never
  # stand a student there — however fat that rung's own discount looks.
  test 'the example never stands on a rung the floor rules out' do
    shop!
    rank(name: 'Rekrut', threshold: 0, discount: 30)
    kapitan = rank(name: 'Kapitan', threshold: 100, discount: 10)
    @poprawa.update!(price: 100, min_rank_for_discount: kapitan)

    5.times do
      get edit_story_group_item_path(@story_group, @poprawa)

      assert_select EXAMPLE, /z rangą Kapitan /
      assert_select EXAMPLE, { text: /Rekrut/, count: 0 }
    end
  end

  test 'discounts that overshoot the cap get a note saying so' do
    shop!
    rank(name: 'Kapitan', threshold: 100, discount: 40)
    badge(name: 'Nawigator', discount: 40)

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select '.gh-warn2 span',
                  "Zniżki sumują się do 80%, a sklep odejmie najwyżej #{Discount::CAP_VALUE}%. " \
                  'Nadwyżka przepada — rozważ niższe zniżki przy rangach i odznakach.'
    assert_select MAXIMUM, /uzyska zniżkę #{Discount::CAP_VALUE}%\./
  end

  test 'discounts inside the cap get no note' do
    shop!
    rank(name: 'Kapitan', threshold: 100, discount: 20)
    badge(name: 'Nawigator', discount: 20)

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select '.gh-warn2 span', { text: /sumują się/, count: 0 }
    assert_select MAXIMUM, /uzyska zniżkę 40%\./
  end

  # The preview needs both numbers off a rung: the ceiling it implies for the
  # card's chip, and its own cut for an example student standing on it.
  test 'each rank option carries its own cut as well as the ceiling it implies' do
    shop!
    rank(name: 'Rekrut', threshold: 0, discount: 5)
    rank(name: 'Kapitan', threshold: 100, discount: 20)

    get edit_story_group_item_path(@story_group, @poprawa)

    options   = css_select('select#item_min_rank_for_discount_id option')
    own       = options.map { |option| option['data-gh-own'] }
    own_names = options.map { |option| option['data-gh-own-name'] }
    ceiling   = options.map { |option| option['data-gh-discount'] }
    reach     = options.map { |option| option['data-gh-name'] }

    assert_equal %w[0 5 20],  own
    assert_equal ['', 'Rekrut', 'Kapitan'], own_names
    # The ceiling a floor implies is a DIFFERENT rung from the floor itself.
    assert_equal %w[0 20 20], ceiling
    assert_equal ['', 'Kapitan', 'Kapitan'], reach
  end

  test 'the form hands the preview the shuffle both sides sample from' do
    shop!
    rank(name: 'Kapitan', threshold: 100, discount: 15)
    %w[Alfa Beta].each { |name| badge(name: name, discount: 5) }

    get edit_story_group_item_path(@story_group, @poprawa)

    form = css_select('form[data-controller=item-form]').first
    assert_equal ['Kapitan'], JSON.parse(form['data-item-form-example-rank-order-value'])
    assert_equal %w[Alfa Beta], JSON.parse(form['data-item-form-example-badge-order-value']).sort
  end

  # The one number this screen duplicates across languages, because the preview
  # has to cap a discount live. A mismatch would have the card promise a saving
  # the till refuses.
  test 'the discount cap in item_form_controller matches Discount::CAP_VALUE' do
    source = Rails.root.join('app/javascript/redesign/item_form_controller.ts').read

    assert_equal "const DISCOUNT_CAP = #{Discount::CAP_VALUE}",
                 source[/^const DISCOUNT_CAP = \d+/],
                 'item_form_controller.ts and Discount::CAP_VALUE have drifted.'
  end

  # `.gh-art-slot` is display:contents, which is what keeps the SVG itself the
  # grid item of the well — otherwise .gh-gph's percentage width resolves
  # against an indefinite box and the glyph lands off-centre at its intrinsic
  # size.
  test 'the preview art sits in a slot that does not become the grid item' do
    get new_story_group_item_path(@story_group)

    assert_select '.gh-pvcard .gh-art > .gh-art-slot > svg.gh-gph'
  end

  # The preview exists to show the button a student will see. `disabled` would
  # grey it out; tabindex and pointer-events keep it inert without that.
  test 'the preview buy button looks live but is not reachable' do
    get new_story_group_item_path(@story_group)

    assert_select '.gh-pvcard .gh-foot .gh-btn[disabled]', false
    assert_select '.gh-pvcard .gh-foot .gh-btn[tabindex=?]', '-1'
  end

  # --- artwork is required --------------------------------------------------

  test 'an item cannot be saved without a preset or an upload' do
    assert_no_difference -> { Item.count } do
      post story_group_items_path(@story_group), params: form_params(icon_glyph: '')
    end

    assert_response :unprocessable_content
    assert_select '.gh-pz-grid[aria-invalid=true]'
    assert_select '.gh-err[role=alert] span', 'Wybierz gotową grafikę albo wgraj własną.'
  end

  test 'an upload alone satisfies the art requirement' do
    file = fixture_file_upload('rank_art.png', 'image/png')

    assert_difference -> { Item.count }, 1 do
      post story_group_items_path(@story_group), params: form_params(icon: file, icon_glyph: '')
    end
  end

  # --- what can actually be sealed ------------------------------------------

  # A rank at threshold 0 is held by every student from the moment they join, so
  # gating on it gates nobody.
  test 'an item gated only on the starting rank can be bought by anyone' do
    shop!
    @poprawa.update!(unlock_rank: rank(name: 'Rekrut', threshold: 0))

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select '.gh-seg2 button[value=sealed][disabled]'
    assert_select '.gh-hint', 'Bez wymagań przedmiot nigdy nie będzie zapieczętowany.'
    assert_select UNLOCK, /\AKażdy student może kupić ten przedmiot/
    assert_select '.gh-pvcard .gh-req li', false
  end

  test 'the starting rank is not a lock on the teacher list either' do
    shop!
    @poprawa.update!(unlock_rank: rank(name: 'Rekrut', threshold: 0))

    get story_group_items_path(@story_group)

    assert_select '.gh-tag--lock', false
  end

  test 'a badge beside the starting rank seals the item again, and names itself' do
    shop!
    @poprawa.update!(unlock_rank: rank(name: 'Rekrut', threshold: 0))
    @poprawa.unlock_badges << badge(name: 'Nawigator')

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select '.gh-seg2 button[value=sealed][disabled]', false
    # The seal names the badge, not the rank nobody can miss.
    assert_select '.gh-seal span', 'Za odznakę Nawigator'
    assert_select '.gh-pvcard .gh-req li', 1
  end

  test 'the unlock rank select says which rungs actually gate' do
    shop!
    rank(name: 'Rekrut', threshold: 0)
    rank(name: 'Kapitan', threshold: 100)

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_select 'select[name=?] option[data-gh-gates=true]', 'item[unlock_rank_id]', 1
    assert_select 'select[name=?] option[data-gh-gates=false]', 'item[unlock_rank_id]', 2
  end

  # --- art ------------------------------------------------------------------

  test 'a preset renders as inline SVG so it can take the item colour' do
    shop!

    get story_group_items_path(@story_group)

    assert_select '.gh-art svg.gh-gph'
    assert_select '.gh-art img', false
  end

  test 'an upload wins over a preset in the same submission' do
    file = fixture_file_upload('rank_art.png', 'image/png')

    post story_group_items_path(@story_group), params: form_params(icon: file, icon_glyph: 'flask')

    created = Item.order(:id).last
    assert created.icon.attached?
    assert_nil created.icon_glyph
    assert created.upload?
  end

  # --- deleting -------------------------------------------------------------

  test 'the delete dialog names the consequence and the copies already sold' do
    shop!
    membership = FactoryBot.create(:story_group_student, story_group: @story_group,
                                                         user:        FactoryBot.create(:user, role: :student),)
    FactoryBot.create(:students_item, story_group_student: membership, item: @poprawa)

    get confirm_destroy_story_group_item_path(@story_group, @poprawa), headers: MODAL

    assert_response :success
    assert_select 'h2', 'Usunąć „Poprawa wejściówki” ze sklepu?'
    assert_select 'p', /zostanie oznaczony jako „Usunięty z oferty”/
    assert_select '.gh-warn span', /1 student ma ten przedmiot/
  end

  test 'deleting is soft and leaves the purchase alone' do
    shop!
    membership = FactoryBot.create(:story_group_student, story_group: @story_group,
                                                         user:        FactoryBot.create(:user, role: :student),)
    purchase = FactoryBot.create(:students_item, story_group_student: membership, item: @poprawa)

    assert_no_difference -> { Item.count } do
      delete story_group_item_path(@story_group, @poprawa)
    end

    assert_predicate @poprawa.reload, :deleted?
    assert_equal @poprawa, purchase.reload.item
    assert_turbo_redirected_to story_group_items_url(@story_group)
  end

  test 'a deleted item leaves the teacher list and the shop' do
    shop!
    @poprawa.soft_delete!

    get story_group_items_path(@story_group)
    assert_equal ['Dodatkowe życie', 'Konsultacja'], card_names('.gh-lgrid')

    student = FactoryBot.create(:user, role: :student)
    FactoryBot.create(:story_group_student, story_group: @story_group, user: student)
    sign_in_as student

    get story_group_shop_index_path(@story_group)
    assert_response :success
    assert_no_match 'Poprawa wejściówki', response.body
  end

  test 'a deleted item has no edit page of its own' do
    shop!
    @poprawa.soft_delete!

    get edit_story_group_item_path(@story_group, @poprawa)

    assert_redirected_to root_path
  end

  # Without this, an invisible item would block a rank deletion forever, with
  # nothing on any screen for the teacher to fix.
  test 'soft delete releases the rank it required, so the rank can go' do
    shop!
    kapitan = rank(name: 'Kapitan', threshold: 100)
    nawigator = badge(name: 'Nawigator')
    @poprawa.update!(unlock_rank: kapitan, min_rank_for_discount: kapitan)
    @poprawa.unlock_badges << nawigator

    @poprawa.soft_delete!

    assert_nil @poprawa.reload.unlock_rank_id
    assert_nil @poprawa.min_rank_for_discount_id
    assert_empty @poprawa.unlock_badges.reload
    assert_empty kapitan.dependent_items

    assert_difference -> { Rank.count }, -1 do
      delete story_group_rank_path(@story_group, kapitan)
    end
  end

  # --- authorization --------------------------------------------------------

  test 'a student of the group cannot reach any of these screens' do
    shop!
    student = FactoryBot.create(:user, role: :student)
    FactoryBot.create(:story_group_student, story_group: @story_group, user: student)
    sign_in_as student

    get story_group_items_path(@story_group)
    assert_redirected_to root_path

    get new_story_group_item_path(@story_group)
    assert_redirected_to root_path

    get edit_story_group_item_path(@story_group, @poprawa)
    assert_redirected_to root_path
  end

  test 'a teacher from another group cannot reach them either' do
    shop!
    sign_in_as FactoryBot.create(:user, role: :teacher)

    get story_group_items_path(@story_group)

    assert_redirected_to root_path
  end

  # --- presentation ---------------------------------------------------------

  test 'the screens run on the redesign layout' do
    shop!

    get story_group_items_path(@story_group)

    assert_select 'link[href*=?]', 'redesign'
    assert_select 'main#app-content'
  end

  test 'there is no show action' do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path(
        "/story_groups/#{@story_group.id}/items/1", method: :get,
      )
    end
  end
end
