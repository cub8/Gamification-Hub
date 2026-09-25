# frozen_string_literal: true

require 'test_helper'

# The Rangi screens: the teacher's editable ladder (#/t/ranks,
# js-expanded/30-lists.js:25-29), the student's progress through it (#/s/ranks,
# 30-sp.js:21-24) and the form page behind both (30-br.js).
class RanksSmokeTest < ActionDispatch::IntegrationTest
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

  def rank(name:, min:, discount: 0, glyph: 'chev1')
    FactoryBot.create(:rank, story_group: @story_group, name: name,
                             required_currency_value: min, discount: discount,
                             icon_glyph: glyph,)
  end

  # Rekrut 0, Królik 40, Pilot 80 — the seed ladder, shortened.
  def ladder!
    @rekrut = rank(name: 'Rekrut', min: 0)
    @krolik = rank(name: 'Kosmiczny Królik', min: 40, discount: 3, glyph: 'chev2')
    @pilot  = rank(name: 'Pilot Marcheton-7', min: 80, discount: 5, glyph: 'rocket')
  end

  def join_as_student(total:)
    student = FactoryBot.create(:user, role: :student)
    membership = FactoryBot.create(:story_group_student, story_group: @story_group, user: student)
    membership.update!(total_currency: total)
    sign_in_as student
    membership
  end

  def attach_art(rank)
    rank.icon.attach(io: Rails.root.join('test/fixtures/files/rank_art.png').open,
                     filename: 'rank_art.png', content_type: 'image/png',)
    rank
  end

  def form_params(name: 'Admirał', min: 120, discount: 7, glyph: 'crown')
    {
      rank: {
        name:                    name,
        required_currency_value: min,
        discount:                discount,
        icon_glyph:              glyph,
      },
    }
  end

  def rows
    css_select('.gh-rlad .gh-rl').map { |row| row.css('b').first.text.strip }
  end

  # --- the teacher ladder ---------------------------------------------------

  test 'the teacher gets the ladder highest first, with the create action' do
    ladder!

    get story_group_ranks_path(@story_group)

    assert_response :success
    assert_select 'h1.gh-h1', 'Rangi'
    assert_equal ['Pilot Marcheton-7', 'Kosmiczny Królik', 'Rekrut'], rows
    assert_select '.gh-rowb a[href=?]', new_story_group_rank_path(@story_group), 'Nowa ranga'
  end

  test 'the lead counts the rungs in Polish' do
    ladder!

    get story_group_ranks_path(@story_group)

    assert_select '.gh-lead', /\A3 rangi\./
  end

  test 'the gap between two rungs is printed between them' do
    ladder!

    get story_group_ranks_path(@story_group)

    gaps = css_select('.gh-rlad .gh-rgap').map { |gap| gap.text.strip }
    # Highest first, so the gaps read 80-40 then 40-0.
    assert_equal ['↑ 40 zebranych do awansu', '↑ 40 zebranych do awansu'], gaps
  end

  test 'a rank at zero is the starting rank and one above zero is not' do
    ladder!

    get story_group_ranks_path(@story_group)

    assert_select '.gh-rl small', 'Ranga startowa, bez zniżki'
    assert_select '.gh-rl small', 'Od 40 zebranych, −3% w sklepie'
  end

  # The mockup calls its lowest rung "Ranga startowa" by array index
  # (30-lists.js:28). A group may define no rank at 0 at all.
  test 'a ladder whose lowest rung is not at zero has no starting rank' do
    rank(name: 'Adept', min: 30)

    get story_group_ranks_path(@story_group)

    assert_select '.gh-rl small', 'Od 30 zebranych, bez zniżki'
    assert_select '.gh-rl small', { text: 'Ranga startowa, bez zniżki', count: 0 }
  end

  test 'each rung counts the students standing on it' do
    ladder!
    [0, 45, 50, 200].each do |total|
      membership = FactoryBot.create(:story_group_student, story_group: @story_group,
                                                           user:        FactoryBot.create(:user, role: :student),)
      membership.update!(total_currency: total)
    end

    get story_group_ranks_path(@story_group)

    counts = css_select('.gh-rl .gh-rl-s b').map { |cell| cell.text.strip }
    assert_equal %w[1 2 1], counts
  end

  test 'a rank required by an item says which items' do
    ladder!
    FactoryBot.create(:item, story_group: @story_group, name: '0.5% oceny', unlock_rank: @pilot)

    get story_group_ranks_path(@story_group)

    assert_select '.gh-req2', 'Wymagana do zakupu: 0.5% oceny'
  end

  test 'a group with no ranks tells the teacher what to do about it' do
    get story_group_ranks_path(@story_group)

    assert_select '.gh-rlad', false
    assert_select '.gh-gm .gh-h2', 'Nie ma jeszcze żadnych rang'
  end

  # --- the student ladder ---------------------------------------------------

  test 'a student sees their own rank marked and the rest as done or locked' do
    ladder!
    join_as_student(total: 50)

    get story_group_ranks_path(@story_group)

    assert_response :success
    assert_select '.gh-rlad', false
    assert_select '.gh-srk--current .gh-youtag', 'Twoja ranga'
    assert_select '.gh-srk--current b', /Kosmiczny Królik/
    assert_select '.gh-srk--done b', /Rekrut/
    assert_select '.gh-srk--locked b', /Pilot Marcheton-7/
    assert_select '.gh-srk--current .gh-st3', '50 z 80 do następnej'
  end

  test 'a student on the top rung is told so' do
    ladder!
    join_as_student(total: 500)

    get story_group_ranks_path(@story_group)

    assert_select '.gh-srk--current .gh-st3', 'Najwyższa ranga'
  end

  # The mockup cannot render this: rankIdx() falls back to index 0, so its
  # student always holds something.
  test 'a student below every threshold holds no rank and aims at the lowest' do
    rank(name: 'Adept', min: 30)
    rank(name: 'Mistrz', min: 90)
    join_as_student(total: 10)

    get story_group_ranks_path(@story_group)

    assert_select '.gh-youtag', false
    assert_select '.gh-srk--current', false
    assert_select '.gh-srk--next .gh-st3', '10 z 30 do pierwszej rangi'
    assert_select '.gh-srk--locked .gh-st3', 'Brakuje 80'
  end

  test 'a student in a group with no ranks gets their own empty state' do
    join_as_student(total: 10)

    get story_group_ranks_path(@story_group)

    assert_select '.gh-gm .gh-h2', 'W tej grupie nie ma jeszcze rang'
  end

  # --- creating and editing -------------------------------------------------

  test 'the new form is a page, starts both numbers at zero and offers presets' do
    get new_story_group_rank_path(@story_group)

    assert_response :success
    assert_select 'header.gh-hd', 1
    assert_select 'main#app-content turbo-frame#modal', false
    assert_select 'h1.gh-h1', 'Nowa ranga'
    assert_select 'input[name=?][value=?]', 'rank[required_currency_value]', '0'
    assert_select 'input[name=?][value=?]', 'rank[discount]', '0'
    assert_select '.gh-preset-tile-grid .gh-preset-tile--rank input[type=radio]', Glyphs::RANK.size
    # The "Twoja grafika" tile is always in the markup so JavaScript can reveal
    # and select it the moment a file is chosen, but there is nothing to show
    # yet — and no src at all, since an empty one would make the browser
    # re-request this page as an image.
    assert_select '.gh-preset-tile--own[hidden]', 1
    assert_select '.gh-preset-tile--own img[src]', false
  end

  test 'the image field offers presets, an upload and a crop box' do
    get new_story_group_rank_path(@story_group)

    assert_select '.gh-preset-tile-grid[role=radiogroup][aria-label=?]', 'Gotowe grafiki'
    assert_select '.gh-preset-tile input[aria-label=?]', 'Grafika: Korona'
    assert_select '.gh-drop input[type=file][accept=?]', 'image/png,image/jpeg,image/gif'
    assert_select '.gh-crop[hidden] .gh-crop-box', 1
  end

  # The crop is cut to the shape of the hole it goes into — .gh-art's
  # `aspect-ratio: 16 / 10` (card.css). A square crop could never fill the card.
  test 'the crop is locked to the shape of the card' do
    get new_story_group_rank_path(@story_group)

    field = css_select('[data-controller=image-crop]').first
    assert_not_nil field
    assert_equal '1.6', field['data-image-crop-aspect-value']
    assert_equal '1024', field['data-image-crop-width-value']
  end

  # Dragging the crop box has to move the preview card and the drabinka
  # thumbnail with it, which the form hears as an event off the image field.
  test 'the form listens for the crop so the preview can follow it' do
    get new_story_group_rank_path(@story_group)

    assert_select 'form[data-action=?]', 'gh:image-crop->rank-form#art'
  end

  test 'the form hands the preview everything it needs to recompute' do
    ladder!
    [10, 50, 90].each do |total|
      membership = FactoryBot.create(:story_group_student, story_group: @story_group,
                                                           user:        FactoryBot.create(:user, role: :student),)
      membership.update!(total_currency: total)
    end

    get new_story_group_rank_path(@story_group)

    form = css_select('form[data-controller=rank-form]').first
    assert_not_nil form
    assert_equal [10, 50, 90], JSON.parse(form['data-rank-form-totals-value'])
    assert_equal([0, 40, 80], JSON.parse(form['data-rank-form-rungs-value']).map { |rung| rung['min'] })
    assert_equal '0', form['data-rank-form-editing-id-value']
    assert_select '[data-rank-form-target=impact]', 1
    assert_select '[data-rank-form-target=ladder]', 1
  end

  test 'creating a rank says so and returns to the ladder' do
    assert_difference('Rank.count', 1) do
      post story_group_ranks_path(@story_group), params: form_params
    end

    assert_redirected_to story_group_ranks_path(@story_group)
    assert_equal 'Dodano rangę „Admirał”.', flash[:notice]
  end

  test 'a blank name is refused on the field' do
    assert_no_difference('Rank.count') do
      post story_group_ranks_path(@story_group), params: form_params(name: '')
    end

    assert_response :unprocessable_content
    assert_select '.gh-inp--bad input[name=?]', 'rank[name]'
    assert_select '#gh-rank-name-error span', 'Podaj nazwę rangi.'
  end

  test 'a threshold another rank already holds is refused and names it' do
    ladder!

    assert_no_difference('Rank.count') do
      post story_group_ranks_path(@story_group), params: form_params(min: 40)
    end

    assert_response :unprocessable_content
    assert_select '#gh-rank-min-error span', 'Ranga Kosmiczny Królik ma już próg 40. Wybierz inny.'
  end

  test 'a glyph outside the rank presets is refused' do
    assert_no_difference('Rank.count') do
      post story_group_ranks_path(@story_group), params: form_params(glyph: 'rabbit')
    end

    assert_response :unprocessable_content
  end

  # The bug in the mockup's own preview (30-br.js:32): it splices the draft in
  # at a hardcoded index, so editing any other rank shows it twice.
  test 'editing a threshold moves the rung instead of duplicating it' do
    ladder!

    assert_no_difference('Rank.count') do
      patch story_group_rank_path(@story_group, @rekrut),
            params: form_params(name: 'Rekrut', min: 60, discount: 0)
    end

    assert_redirected_to story_group_ranks_path(@story_group)
    get story_group_ranks_path(@story_group)
    assert_equal ['Pilot Marcheton-7', 'Rekrut', 'Kosmiczny Królik'], rows
  end

  test 'the edit preview shows the draft in place of the rank being edited' do
    ladder!

    get edit_story_group_rank_path(@story_group, @krolik)

    assert_response :success
    # Three rungs, never four: the draft IS the edited rank.
    assert_select '.gh-ladder .gh-lad', 3
    assert_select '.gh-ladder .gh-lad--new', 1
    assert_select '.gh-ladder .gh-lad--new [data-rank-form-target=draftName]', 'Kosmiczny Królik'
    assert_select ".gh-ladder .gh-lad[data-rank-id=#{@krolik.id}]", false
  end

  # --- deleting -------------------------------------------------------------

  test 'the confirm dialog spells out the consequence' do
    ladder!

    get confirm_destroy_story_group_rank_path(@story_group, @pilot), headers: MODAL

    assert_response :success
    assert_select 'h2', 'Usunąć rangę „Pilot Marcheton-7”?'
    assert_select 'p', 'Studenci z tą rangą spadną do rangi niżej.'
    assert_select '.gh-warn', false
  end

  test 'deleting an unreferenced rank works and leaves the dialog' do
    ladder!

    assert_difference('Rank.count', -1) do
      delete story_group_rank_path(@story_group, @pilot), headers: MODAL
    end

    assert_turbo_redirected_to story_group_ranks_url(@story_group)
    assert_equal 'Usunięto rangę „Pilot Marcheton-7”.', flash[:notice]
  end

  test 'a rank an item requires cannot be deleted and the items are named' do
    ladder!
    FactoryBot.create(:item, story_group: @story_group, name: '0.5% oceny', unlock_rank: @pilot)
    FactoryBot.create(:item, story_group: @story_group, name: 'Bezpieczna poprawa',
                             min_rank_for_discount: @pilot,)

    get confirm_destroy_story_group_rank_path(@story_group, @pilot), headers: MODAL
    assert_select '.gh-warn span', /0\.5% oceny i Bezpieczna poprawa/
    assert_select '.gh-dlg-b button[disabled]', 'Usuń rangę'

    # Refused server-side too: the disabled button is a courtesy, the foreign
    # keys on items are the reason.
    assert_no_difference('Rank.count') do
      delete story_group_rank_path(@story_group, @pilot), headers: MODAL
    end

    assert_turbo_redirected_to story_group_ranks_url(@story_group)
    assert_match(/Nie można usunąć rangi/, flash[:alert])
  end

  test 'the delete warning agrees with itself about how many items there are' do
    ladder!
    FactoryBot.create(:item, story_group: @story_group, name: '0.5% oceny', unlock_rank: @pilot)

    get confirm_destroy_story_group_rank_path(@story_group, @pilot), headers: MODAL
    assert_select '.gh-warn span', /Przedmiot 0\.5% oceny wymaga tej rangi\./
    assert_select '.gh-warn span', /przypisz mu inną rangę/

    FactoryBot.create(:item, story_group: @story_group, name: 'Bezpieczna poprawa',
                             unlock_rank: @pilot,)

    get confirm_destroy_story_group_rank_path(@story_group, @pilot), headers: MODAL
    assert_select '.gh-warn span', /Przedmioty .* wymagają tej rangi\./
    assert_select '.gh-warn span', /przypisz im inną rangę/
  end

  # --- art ------------------------------------------------------------------

  test 'a preset is inlined so it can take the card colour' do
    ladder!

    get story_group_ranks_path(@story_group)

    # Inline SVG, not <img>: .gh-gph strokes in currentColor, which is what
    # makes the same shape gold here and teal on a badge.
    assert_select '.gh-rl .gh-mc svg.gh-gph', 3
    assert_select '.gh-rl .gh-mc img', false
  end

  test 'an uploaded icon becomes the art and the picker agrees' do
    ladder!
    attach_art(@pilot)
    @pilot.update!(icon_glyph: nil)

    get story_group_ranks_path(@story_group)
    assert_select ".gh-rl img[alt='']", 1

    get edit_story_group_rank_path(@story_group, @pilot)
    assert_select '.gh-preset-tile--own[hidden]', false
    assert_select '.gh-preset-tile--own input[checked=checked]', 1
  end

  # Without JavaScript nothing would ever select the upload: the picker's own
  # tile is hidden until there is something attached.
  test 'uploading a file wins over whatever preset was selected' do
    ladder!

    patch story_group_rank_path(@story_group, @pilot),
          params: {
            rank: {
              name:                    @pilot.name,
              required_currency_value: 80,
              discount:                5,
              icon_glyph:              'crown',
              icon:                    fixture_file_upload('rank_art.png', 'image/png'),
            },
          }

    assert_redirected_to story_group_ranks_path(@story_group)
    assert_nil @pilot.reload.icon_glyph
    assert_predicate @pilot.icon, :attached?
    assert_equal :upload, @pilot.art
  end

  test 'picking a preset keeps the upload so you can switch back' do
    ladder!
    attach_art(@pilot)
    @pilot.update!(icon_glyph: nil)

    patch story_group_rank_path(@story_group, @pilot),
          params: {
            rank: {
              name:                    @pilot.name,
              required_currency_value: 80,
              discount:                5,
              icon_glyph:              'crown',
            },
          }

    assert_equal 'crown', @pilot.reload.icon_glyph
    assert_predicate @pilot.icon, :attached?
    assert_equal 'crown', @pilot.art
  end

  # --- presentation ---------------------------------------------------------

  test 'the confirm dialog carries one modal frame, and none as a page' do
    ladder!
    path = confirm_destroy_story_group_rank_path(@story_group, @pilot)

    get path, headers: MODAL
    assert_select 'turbo-frame#modal', 1

    get path
    assert_select 'main#app-content turbo-frame#modal', false
    assert_select 'main .gh-panel.gh-dlg-page', 1
    assert_select 'header.gh-hd', 1
  end

  test 'creating says so in a toast, not in a banner' do
    post story_group_ranks_path(@story_group), params: form_params

    get story_group_ranks_path(@story_group)

    assert_select '#gh-toasts template[data-toast-target=seed]', 'Dodano rangę „Admirał”.'
    assert_select '#flash-messages', false
  end

  # The mockup has no rank detail: the row IS the detail and editing is a page.
  test 'there is no rank detail screen' do
    ladder!

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path(
        "/story_groups/#{@story_group.id}/ranks/#{@pilot.id}", method: :get,
      )
    end
  end

  # --- authorization --------------------------------------------------------

  test 'a student cannot open the form or write' do
    ladder!
    join_as_student(total: 50)

    get new_story_group_rank_path(@story_group)
    assert_redirected_to root_path

    post story_group_ranks_path(@story_group), params: form_params
    assert_redirected_to root_path

    delete story_group_rank_path(@story_group, @pilot)
    assert_redirected_to root_path
  end

  test 'a supporting teacher may manage ranks' do
    supporter = FactoryBot.create(:user, role: :teacher)
    FactoryBot.create(:story_group_teacher, story_group: @story_group, user: supporter)
    sign_in_as supporter

    get new_story_group_rank_path(@story_group)

    assert_response :success
  end
end
