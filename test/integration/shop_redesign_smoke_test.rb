# frozen_string_literal: true

require 'test_helper'

# Sklep, the student's shop (#/s/shop, js-expanded/30-main.js:87-98) and the
# buy confirmation behind its button (dlgBuy(), :200-207).
#
# The card itself is items/_card, the same partial the teacher's form preview
# renders — what is tested here is that a STUDENT'S answers reach it: their
# price, their missing requirements, their progress.
class ShopRedesignSmokeTest < ActionDispatch::IntegrationTest
  MODAL = { 'Turbo-Frame' => 'modal' }.freeze

  setup do
    @owner = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @owner, name: 'Kosmiczne króliki',
                                                   currency_name: 'marchewki',)
    @user = FactoryBot.create(:user, role: :student)
    @student = FactoryBot.create(:story_group_student, user: @user, story_group: @story_group,
                                                       current_currency: 100, total_currency: 100, lives: 3,)
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

  def rank(name:, threshold:, discount: 0)
    FactoryBot.create(:rank, story_group: @story_group, name: name,
                             required_currency_value: threshold, discount: discount,)
  end

  def badge(name:, discount: 0)
    FactoryBot.create(:badge, story_group: @story_group, name: name, discount: discount)
  end

  def visit_shop
    get story_group_shop_index_path(@story_group)
  end

  # The zone a card landed in, by its item name.
  def zone_of(name)
    css_select('.gh-zone').find do |zone|
      zone.css('.gh-card-name').any? { |title| title.text.strip == name }
    end
  end

  # `> span:first-child` throughout: .gh-zone-n is a span in the same label.
  def zone_label(zone) = zone.css('.gh-zone-l > span:first-child').first.text.strip

  def zone_labels = css_select('.gh-zone-l > span:first-child').map { |label| label.text.strip }

  def zone_counts = css_select('.gh-zone-n').map { |count| count.text.strip }

  def requirement_lines(card) = card.css('.gh-req li').map { |line| line.text.squish }

  # --- who may see it ------------------------------------------------------

  test 'a student enrolled in the group gets the shop' do
    visit_shop

    assert_response :success
    assert_select 'h1.gh-h1', 'Sklep'
  end

  # Membership, not role: the owner teaches this group but does not learn in it.
  test "the group's owner is not a shopper here" do
    sign_in_as @owner
    visit_shop

    assert_redirected_to root_path
  end

  test 'a teacher who is also enrolled shops like anyone else' do
    other = FactoryBot.create(:user, role: :teacher)
    FactoryBot.create(:story_group_student, user: other, story_group: @story_group,
                                            current_currency: 5, total_currency: 5, lives: 3,)
    sign_in_as other
    visit_shop

    assert_response :success
    assert_select 'h1.gh-h1', 'Sklep'
  end

  # --- the zones -----------------------------------------------------------

  test 'items are fenced into the three zones, each counted' do
    item(name: 'Tani przedmiot', price: 10)
    item(name: 'Drogi przedmiot', price: 500)
    locked = item(name: 'Zamknięty przedmiot', price: 10)
    locked.unlock_badges << badge(name: 'Mechanik')

    visit_shop

    assert_equal ['Stać cię teraz', 'Zbierasz na to', 'Zapieczętowane'], zone_labels
    assert_equal %w[1 1 1], zone_counts

    assert_equal 'Stać cię teraz',  zone_label(zone_of('Tani przedmiot'))
    assert_equal 'Zbierasz na to',  zone_label(zone_of('Drogi przedmiot'))
    assert_equal 'Zapieczętowane',  zone_label(zone_of('Zamknięty przedmiot'))
  end

  # An empty zone is not rendered at all: a dashed frame around nothing reads
  # as a fault rather than as an absence.
  test 'a zone with nothing in it is absent, not empty' do
    item(name: 'Tani przedmiot', price: 10)

    visit_shop

    assert_select '.gh-zone', 1
    assert_equal ['Stać cię teraz'], zone_labels
  end

  test 'the head names the balance and the total collected' do
    visit_shop

    assert_select '.gh-phead .gh-lead', /Masz\s+100\s+do wydania\./
    purse = css_select('.gh-purse-mini b').map { |value| value.text.strip }
    assert_equal %w[100 100], purse
  end

  test 'the head names the badges that cut prices, and says nothing when there are none' do
    visit_shop
    assert_select '.gh-phead .gh-lead', { text: /odznak/, count: 0 }

    @student.badges << badge(name: 'Nawigator', discount: 10)
    @student.badges << badge(name: 'Mechanik', discount: 5)
    visit_shop

    assert_select '.gh-phead .gh-lead',
                  /Twoje odznaki\s+Mechanik\s+i\s+Nawigator\s+obniżają ceny niektórych przedmiotów\./
  end

  # --- an affordable card --------------------------------------------------

  test 'an affordable card carries a real buy link into the confirmation' do
    cheap = item(name: 'Tani przedmiot', price: 10)

    visit_shop

    link = css_select(".gh-cards a[href='#{confirm_buy_story_group_shop_path(@story_group, cheap)}']").first
    assert_not_nil link
    assert_equal 'Kup za 10', link.text.strip
    assert_equal 'modal', link['data-turbo-frame']
    assert_select '.gh-card--afford', 1
    assert_select '.gh-seal[hidden]', 1
  end

  # --- the price is the student's, not the list ----------------------------

  test 'a discounted card strikes the list price and names what the discount is for' do
    nawigator = badge(name: 'Nawigator', discount: 20)
    @student.badges << nawigator
    discounted = item(name: 'Poprawa', price: 50)
    discounted.discount_badges << nawigator

    visit_shop

    card = css_select('.gh-card').first
    assert_equal '50', card.css('.gh-cost s').first.text.strip
    assert_equal '40', card.css('.gh-cost b').first.text.strip
    # The student's own percentage, NOT Redesign::ItemCard's "Zniżki do −20%"
    # ceiling, which is what the teacher's screens show.
    assert_equal '−20% za odznaki', card.css('.gh-tag--disc').first.text.strip
  end

  test 'an undiscounted card shows one price and hides the discount chip' do
    item(name: 'Tani przedmiot', price: 10)

    visit_shop

    card = css_select('.gh-card').first
    assert_empty card.css('.gh-cost s')
    assert_equal '10', card.css('.gh-cost b').first.text.strip
    assert_not_nil card.css('.gh-tag--disc[hidden]').first
  end

  # --- saving up -----------------------------------------------------------

  test 'a card you cannot yet afford says how much is missing' do
    item(name: 'Drogi przedmiot', price: 160)

    visit_shop

    card = css_select('.gh-card').first
    assert_equal '60', card.css('.gh-need b').first.text.strip
    assert_includes card.css('.gh-need .gh-bar i').first['style'], '--gh-p: 63%'
    # No button: there is nothing to press yet.
    assert_empty card.css('.gh-foot')
  end

  # --- sealed --------------------------------------------------------------

  test 'a sealed card lists only what THIS student is missing' do
    held    = badge(name: 'Nawigator')
    missing = badge(name: 'Mechanik')
    @student.badges << held

    locked = item(name: 'Konsultacja', price: 10)
    locked.unlock_badges << held
    locked.unlock_badges << missing

    visit_shop

    card = css_select('.gh-card').first
    assert_equal ['Wymaga odznaki Mechanik'], requirement_lines(card)
    assert_equal 'Za odznakę Mechanik', card.css('.gh-seal span').first.text.strip
    assert_nil card.css('.gh-seal').first['hidden']
  end

  # A rank the student already holds gates nothing, so it is neither listed nor
  # stamped — the badge they lack is.
  test 'a rank already held is not a reason the item is sealed' do
    rank(name: 'Rekrut', threshold: 0)
    kapitan = rank(name: 'Kapitan', threshold: 50)
    missing = badge(name: 'Mechanik')

    locked = item(name: 'Konsultacja', price: 10, unlock_rank: kapitan)
    locked.unlock_badges << missing

    visit_shop

    card = css_select('.gh-card').first
    assert_equal ['Wymaga odznaki Mechanik'], requirement_lines(card)
    assert_equal 'Za odznakę Mechanik', card.css('.gh-seal span').first.text.strip
    assert_empty card.css('.gh-req .gh-bar')
  end

  test 'a rank out of reach is listed with a bar toward it' do
    admiral = rank(name: 'Admirał', threshold: 400)
    item(name: 'Flaga', price: 10, unlock_rank: admiral)

    visit_shop

    card = css_select('.gh-card').first
    assert_equal ['Wymaga rangi Admirał'], requirement_lines(card)
    bar = card.css('.gh-req .gh-bar').first
    assert_equal '400', bar['aria-valuemax']
    assert_equal '100', bar['aria-valuenow']
    assert_equal 'Postęp do rangi Admirał', bar['aria-label']
  end

  test 'no lives left seals everything that does not say otherwise' do
    @student.update!(lives: 0)
    item(name: 'Zwykły przedmiot', price: 10)
    item(name: 'Dodatkowe życie', price: 10, can_buy_at_0_lives: true)

    visit_shop

    sealed = zone_of('Zwykły przedmiot')
    assert_equal 'Zapieczętowane', zone_label(sealed)
    assert_equal 'Stać cię teraz', zone_label(zone_of('Dodatkowe życie'))

    card = sealed.css('.gh-card').first
    assert_equal ['Masz 0 żyć. Najpierw odzyskaj życie.'], requirement_lines(card)
    assert_equal 'Niedostępne przy 0 życiach', card.css('.gh-seal span').first.text.strip
  end

  # --- the buy confirmation ------------------------------------------------

  test 'the confirmation quotes the price, the remainder and the discount' do
    nawigator = badge(name: 'Nawigator', discount: 20)
    @student.badges << nawigator
    bought = item(name: 'Poprawa', price: 50)
    bought.discount_badges << nawigator

    get confirm_buy_story_group_shop_path(@story_group, bought), headers: MODAL

    assert_response :success
    assert_select 'turbo-frame#modal'
    assert_select 'h2', 'Kupić „Poprawa”?'
    labels = css_select('.gh-buy-dl dt').map { |term| term.text.strip }
    assert_equal ['Cena', 'Zostanie Ci'], labels
    values = css_select('.gh-buy-dl .gh-buy-v').map { |dd| dd.text.strip }
    assert_equal %w[40 60], values
    assert_equal '50', css_select('.gh-buy-dl s').first.text.strip
    assert_select '.gh-note', /Zniżka −20% za odznaki\./
    assert_select '.gh-note', /Prowadzący dostanie powiadomienie o zakupie\./
  end

  test 'the confirmation posts to buy and breaks out of the frame' do
    bought = item(name: 'Poprawa', price: 10)

    get confirm_buy_story_group_shop_path(@story_group, bought), headers: MODAL

    form = css_select("form[action='#{buy_story_group_shop_path(@story_group, bought)}']").first
    assert_not_nil form
    assert_equal '_top', form['data-turbo-frame']
    assert_select '.gh-dlg-b button', 'Kup za 10'
  end

  # Ctrl-click, or no JavaScript: the same content as a page on the app shell.
  test 'the confirmation renders as a page outside the frame' do
    bought = item(name: 'Poprawa', price: 10)

    get confirm_buy_story_group_shop_path(@story_group, bought)

    assert_response :success
    assert_select 'turbo-frame#modal .gh-buy', false
    assert_select '.gh-panel.gh-dlg-page .gh-buy'
    assert_select ".gh-dlg-b a[href='#{story_group_shop_index_path(@story_group)}']", 'Anuluj'
  end

  # The dialog quotes a price, so it re-checks the offer rather than trusting
  # the page the link came off.
  test 'the confirmation refuses an item this student cannot buy' do
    poor = item(name: 'Drogi przedmiot', price: 500)

    get confirm_buy_story_group_shop_path(@story_group, poor)

    assert_redirected_to story_group_shop_index_path(@story_group)
    assert_equal 'Nie możesz teraz kupić „Drogi przedmiot”.', flash[:alert]
  end

  test 'the confirmation refuses a sealed item' do
    locked = item(name: 'Konsultacja', price: 10)
    locked.unlock_badges << badge(name: 'Mechanik')

    get confirm_buy_story_group_shop_path(@story_group, locked)

    assert_redirected_to story_group_shop_index_path(@story_group)
  end

  # --- buying --------------------------------------------------------------

  test 'buying takes the money, keeps the copy and raises a toast' do
    bought = item(name: 'Poprawa', price: 40)

    assert_difference -> { @student.students_items.count }, 1 do
      post buy_story_group_shop_path(@story_group, bought)
    end

    assert_redirected_to story_group_shop_index_path(@story_group)
    assert_equal 60, @student.reload.current_currency
    # Spending never lowers the total collected, so the rank is untouched.
    assert_equal 100, @student.total_currency

    follow_redirect!
    assert_select '#gh-toasts template[data-toast-target=seed]', 'Kupione: „Poprawa”. Zostało Ci 60.'
  end

  test 'buying something you cannot afford leaves an inline alert' do
    poor = item(name: 'Drogi przedmiot', price: 500)

    assert_no_difference -> { @student.students_items.count } do
      post buy_story_group_shop_path(@story_group, poor)
    end

    follow_redirect!
    assert_select '#flash-messages [role=alert]', /za mało waluty/
  end

  # --- soft delete ---------------------------------------------------------

  test 'an item withdrawn from the offer is gone from every zone and cannot be bought' do
    gone = item(name: 'Wycofany przedmiot', price: 10)
    gone.soft_delete!

    visit_shop
    assert_select '.gh-card', 0
    assert_select '.gh-gm h2', 'Sklep jest jeszcze pusty'

    # `kept` at the finder, so the record is simply not there — the app's own
    # RecordNotFound rescue sends you home.
    get confirm_buy_story_group_shop_path(@story_group, gone)
    assert_redirected_to root_path
  end

  # --- no detail screen ----------------------------------------------------

  # The card carries everything a detail page would, at every width, so there
  # is nothing for one to add and nothing links to it.
  test 'the shop has no show route' do
    assert_raises(NoMethodError) { story_group_shop_path(@story_group, 1) }
  end

  # --- the header chip -----------------------------------------------------

  test 'the header shows the balance in a group and links to the history' do
    visit_shop

    chip = css_select('.gh-hd a.gh-bal').first
    assert_not_nil chip
    assert_equal story_group_student_currency_transactions_path(@story_group, @student), chip['href']
    assert_equal '100', chip.css('b').first.text.strip
    assert_equal 'do wydania', chip.css('small').first.text.strip
    assert_equal '100 do wydania, 100 zebrane łącznie', chip['title']
  end

  test 'nobody who is not enrolled here carries a balance' do
    sign_in_as @owner
    get story_group_items_path(@story_group)

    assert_response :success
    assert_select '.gh-bal', false
  end

  test 'out of a group there is no balance to show' do
    get home_path

    assert_response :success
    assert_select '.gh-bal', false
  end
end
