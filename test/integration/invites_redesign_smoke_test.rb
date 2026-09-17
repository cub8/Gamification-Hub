# frozen_string_literal: true

require 'test_helper'

# The invite codes screen: the list that groups by whether a code still works,
# and the four dialogs hanging off it (mockup #/t/invites, 30-isg.js:17-45).
class InvitesRedesignSmokeTest < ActionDispatch::IntegrationTest
  MODAL = { 'Turbo-Frame' => 'modal' }.freeze

  setup do
    @owner = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @owner, name: 'Zakon Algorytmów')
    sign_in @owner
  end

  # An invite bypassing validation, so a test can set up a code that is already
  # dead — which the form is not allowed to create.
  def invite(uses: 0, max_uses: nil, expires_at: nil)
    record = FactoryBot.build(:story_group_invite, story_group: @story_group,
                                                   max_uses: max_uses, expires_at: nil,)
    record.save!
    record.update_columns(uses: uses, expires_at: expires_at)
    record.reload
  end

  # sign_in is a no-op while a session is live — the magic-link verify refuses
  # to run for someone already logged in — so switching user needs the sign_out.
  def sign_in_as(user)
    sign_out
    sign_in user
  end

  def form_params(limit: false, max_uses: 30, expiry: false, on: Time.zone.tomorrow, at: '23:59')
    {
      story_group_invite: {
        limit_enabled:  limit ? '1' : '0',
        max_uses:       max_uses,
        expiry_enabled: expiry ? '1' : '0',
        expires_on:     on.to_fs(:iso8601),
        expires_time:   at,
      },
    }
  end

  # assert_select cannot select "the row whose code cell says X" — :has with a
  # nested matcher is beyond its selector support — so pick the row in Ruby.
  def row_for(code)
    css_select('.gh-iv').find { |row| row.css('.gh-iv-cd').text.strip == code }
  end

  # --- the list -------------------------------------------------------------

  test 'active codes are listed and dead ones are folded away with a count' do
    live = invite
    expired = invite(expires_at: 1.hour.ago)
    exhausted = invite(uses: 5, max_uses: 5)

    get story_group_invites_path(@story_group)

    assert_response :success
    assert_select '.gh-ivl .gh-iv-cd', text: live.code, count: 1
    assert_select 'details.gh-inact summary', 'Nieaktywne (2): wygasłe i wyczerpane'
    assert_select 'details.gh-inact .gh-iv-cd', text: expired.code, count: 1
    assert_select 'details.gh-inact .gh-iv-cd', text: exhausted.code, count: 1
  end

  test 'the inactive block is absent entirely when every code still works' do
    invite

    get story_group_invites_path(@story_group)

    assert_select 'details.gh-inact', false
  end

  test 'a code that is both expired and exhausted reports the expiry first' do
    invite(uses: 5, max_uses: 5, expires_at: 1.hour.ago)

    get story_group_invites_path(@story_group)

    assert_select '.gh-stt', 'Wygasło'
  end

  test 'only a limited code gets a usage bar, and only a live one gets Pokaz' do
    unlimited = invite
    limited = invite(uses: 3, max_uses: 30)
    dead = invite(expires_at: 1.hour.ago)

    get story_group_invites_path(@story_group)

    assert_equal 1, row_for(limited.code).css('.gh-bar').size
    assert_equal 0, row_for(unlimited.code).css('.gh-bar').size
    assert_select 'a[href=?]', story_group_invite_path(@story_group, limited), count: 1
    assert_select 'a[href=?]', story_group_invite_path(@story_group, dead), count: 0
  end

  test 'uses and expiry read as sentences, tense-aware' do
    invite(uses: 3, max_uses: 30, expires_at: Time.zone.parse('2026-09-30 23:59'))
    invite(uses: 8)

    get story_group_invites_path(@story_group)

    assert_includes css_select('.gh-iv-u').map { |e| e.text.strip }, 'Użycia: 3 z 30'
    assert_includes css_select('.gh-iv-u').map { |e| e.text.strip }, 'Użycia: 8, bez limitu'
    assert_includes css_select('.gh-iv-e').map(&:text), 'Wygasa 30.09, 23:59'
    assert_includes css_select('.gh-iv-e').map(&:text), 'Bez daty ważności'
  end

  test 'the expiry cell switches to the past tense once the date is behind' do
    invite(expires_at: Time.zone.parse('2026-09-01 23:59'))

    get story_group_invites_path(@story_group)

    assert_select '.gh-iv-e', 'Wygasło 01.09, 23:59'
  end

  test 'an empty list explains what to do about it' do
    get story_group_invites_path(@story_group)

    assert_select '.gh-expl', 'Brak aktywnych zaproszeń. Utwórz nowe, żeby studenci mogli dołączyć.'
  end

  # --- creating -------------------------------------------------------------

  test 'both switches off stores no limits at all' do
    assert_difference('StoryGroupInvite.count') do
      post story_group_invites_path(@story_group), params: form_params, headers: MODAL
    end

    created = StoryGroupInvite.order(:created_at).last
    assert_nil created.max_uses
    assert_nil created.expires_at
  end

  test 'both switches on stores the limit and the combined date and time' do
    post story_group_invites_path(@story_group),
         params:  form_params(limit: true, max_uses: 12, expiry: true,
                              on: Date.new(2026, 9, 30), at: '18:30',),
         headers: MODAL

    created = StoryGroupInvite.order(:created_at).last
    assert_equal 12, created.max_uses
    assert_equal Time.zone.parse('2026-09-30 18:30'), created.expires_at
  end

  test 'a limit of zero is refused on the field' do
    assert_no_difference('StoryGroupInvite.count') do
      post story_group_invites_path(@story_group),
           params: form_params(limit: true, max_uses: 0), headers: MODAL
    end

    assert_response :unprocessable_content
    assert_select '.gh-inp--bad #gh-max-uses'
    assert_select '#gh-limit-error span', 'Limit musi wynosić co najmniej 1.'
  end

  test 'a date in the past is refused on the field' do
    assert_no_difference('StoryGroupInvite.count') do
      post story_group_invites_path(@story_group),
           params: form_params(expiry: true, on: Time.zone.today - 1), headers: MODAL
    end

    assert_response :unprocessable_content
    assert_select '.gh-inp--bad #gh-expires-on'
    assert_select '#gh-expiry-error span', 'Ta data już minęła. Wybierz późniejszą.'
  end

  # Regression: the form's own expiry check used to run before the record's
  # validations and short-circuit the save, so a limit error never surfaced.
  test 'a bad limit and a bad date are both reported at once' do
    post story_group_invites_path(@story_group),
         params:  form_params(limit: true, max_uses: 0, expiry: true,
                              on: Time.zone.today - 1,),
         headers: MODAL

    assert_response :unprocessable_content
    assert_select '#gh-limit-error span', 'Limit musi wynosić co najmniej 1.'
    assert_select '#gh-expiry-error span', 'Ta data już minęła. Wybierz późniejszą.'
  end

  test 'the summary sentence covers all four combinations' do
    get new_story_group_invite_path(@story_group), headers: MODAL
    assert_select '#gh-invite-summary', 'Kod będzie działał bez limitu osób i bez daty ważności.'

    post story_group_invites_path(@story_group),
         params: form_params(limit: true, max_uses: 0), headers: MODAL
    assert_select '#gh-invite-summary', 'Kod będzie działał dla 0 osób i bez daty ważności.'

    post story_group_invites_path(@story_group),
         params:  form_params(limit: true, max_uses: 0, expiry: true,
                              on: Date.new(2026, 9, 30), at: '23:59',),
         headers: MODAL
    assert_select '#gh-invite-summary', 'Kod będzie działał dla 0 osób do 30.09, 23:59.'
  end

  test 'the presets are offered when creating and withheld when editing' do
    get new_story_group_invite_path(@story_group), headers: MODAL
    assert_select '.gh-presets .gh-fchip', 2
    assert_select '.gh-presets .gh-fchip', text: 'Na dzisiejsze zajęcia'
    assert_select '.gh-presets .gh-fchip', text: 'Bez ograniczeń'

    get edit_story_group_invite_path(@story_group, invite), headers: MODAL
    assert_select '.gh-presets', false
  end

  test 'creating names the new code and flashes its row once' do
    post story_group_invites_path(@story_group), params: form_params, headers: MODAL
    created = StoryGroupInvite.order(:created_at).last

    assert_equal "Utworzono kod #{created.code}. Kliknij „Pokaż”, żeby wyświetlić go studentom.",
                 flash[:notice]

    get story_group_invites_path(@story_group)
    assert_select '.gh-iv--fresh .gh-iv-cd', created.code

    # One render only — a highlight that stuck around would stop meaning "new".
    get story_group_invites_path(@story_group)
    assert_select '.gh-iv--fresh', false
  end

  # --- editing --------------------------------------------------------------

  test 'editing keeps the code and says so' do
    existing = invite(uses: 3, max_uses: 30)

    get edit_story_group_invite_path(@story_group, existing), headers: MODAL

    assert_select '#gh-invite-title', "Edytuj zaproszenie #{existing.code}"
    assert_select 'p', 'Kod zostaje ten sam. Zmieniasz tylko ograniczenia.'
    assert_select '#gh-max-uses[value=?]', '30'
  end

  test 'a limit cannot be dropped below the people who already joined' do
    existing = invite(uses: 3)

    patch story_group_invite_path(@story_group, existing),
          params: form_params(limit: true, max_uses: 2), headers: MODAL

    assert_response :unprocessable_content
    assert_select '#gh-limit-error span',
                  'Z tego kodu skorzystało już 3 osoby. Limit nie może być mniejszy.'
    assert_nil existing.reload.max_uses
  end

  test 'a limit equal to the uses so far is accepted' do
    existing = invite(uses: 3)

    patch story_group_invite_path(@story_group, existing),
          params: form_params(limit: true, max_uses: 3), headers: MODAL

    assert_equal 3, existing.reload.max_uses
    assert_equal "Zapisano zaproszenie #{existing.code}.", flash[:notice]
  end

  test 'turning a switch off clears the column it stood for' do
    existing = invite(max_uses: 30, expires_at: 2.days.from_now)

    patch story_group_invite_path(@story_group, existing), params: form_params, headers: MODAL

    existing.reload
    assert_nil existing.max_uses
    assert_nil existing.expires_at
  end

  # --- showing --------------------------------------------------------------

  test 'the code dialog is addressed to the student, with the QR and the stats' do
    existing = invite(uses: 3, max_uses: 30, expires_at: Time.zone.parse('2026-09-30 23:59'))

    get story_group_invite_path(@story_group, existing), headers: MODAL

    assert_select '#gh-code-title', 'Dołącz do grupy Zakon Algorytmów'
    assert_select '.gh-qr img[src^=?]', 'data:image/png;base64,'
    assert_select '.gh-code-big', existing.code
    assert_select '.gh-code-big[aria-label=?]', "Kod: #{existing.code.chars.join(' ')}"
    assert_select '.gh-small', 'Użycia: 3 z 30. Wygasa 30.09, 23:59.'
  end

  test 'the code can be copied' do
    existing = invite

    get story_group_invite_path(@story_group, existing), headers: MODAL

    assert_select "[data-controller='clipboard'][data-clipboard-text-value=?]", existing.code
  end

  # --- deleting -------------------------------------------------------------

  test 'the delete dialog says who stays in the group' do
    existing = invite(uses: 8)

    get confirm_destroy_story_group_invite_path(@story_group, existing), headers: MODAL

    assert_select '#gh-del-title', "Usunąć zaproszenie #{existing.code}?"
    assert_select 'p', /8 osób, które dołączyły z tym kodem, zostaje w grupie\./
  end

  test 'the delete dialog says nothing about people when nobody used the code' do
    get confirm_destroy_story_group_invite_path(@story_group, invite), headers: MODAL

    assert_select 'p', 'Kod przestanie działać od razu.'
  end

  test 'deleting removes the code and leaves the dialog' do
    existing = invite

    assert_difference('StoryGroupInvite.count', -1) do
      delete story_group_invite_path(@story_group, existing), headers: MODAL
    end

    assert_turbo_redirected_to story_group_invites_url(@story_group)
    assert_equal "Usunięto zaproszenie #{existing.code}.", flash[:notice]
  end

  # --- presentation ---------------------------------------------------------

  test 'every dialog carries exactly one modal frame, and none as a page' do
    existing = invite

    paths = [new_story_group_invite_path(@story_group),
             edit_story_group_invite_path(@story_group, existing),
             story_group_invite_path(@story_group, existing),
             confirm_destroy_story_group_invite_path(@story_group, existing),]

    paths.each do |path|
      get path, headers: MODAL
      assert_select 'turbo-frame#modal', 1, "#{path} inside the dialog"

      # As a page the only modal frame is the layout's own, inside <dialog>.
      get path
      assert_select 'main#app-content turbo-frame#modal', false, "#{path} as a page"
      assert_select 'header.gh-hd', 1, "#{path} keeps the shell as a page"
    end
  end

  test 'a dialog opened as a page gets a surface, and in the dialog does not' do
    existing = invite

    paths = [new_story_group_invite_path(@story_group),
             edit_story_group_invite_path(@story_group, existing),
             story_group_invite_path(@story_group, existing),
             confirm_destroy_story_group_invite_path(@story_group, existing),]

    paths.each do |path|
      get path
      assert_select 'main .gh-panel.gh-dlg-page', 1, "#{path} as a page sits on a panel"

      # In the dialog the <dialog> itself is the surface.
      get path, headers: MODAL
      assert_select '.gh-dlg-page', false, "#{path} in the dialog needs no panel"
    end
  end

  # --- confirmations --------------------------------------------------------

  test 'creating says so in a toast, not in a banner' do
    post story_group_invites_path(@story_group), params: form_params, headers: MODAL
    created = StoryGroupInvite.order(:created_at).last

    get story_group_invites_path(@story_group)

    assert_select '#gh-toasts template[data-toast-target=seed]',
                  "Utworzono kod #{created.code}. Kliknij „Pokaż”, żeby wyświetlić go studentom."
    assert_select '#flash-messages', false
  end

  test 'the copy button carries the code and what it will say' do
    existing = invite

    get story_group_invites_path(@story_group)

    button = row_for(existing.code).css("[data-controller='clipboard']").first
    assert_equal existing.code, button['data-clipboard-text-value']
    assert_equal "Skopiowano kod #{existing.code}.", button['data-clipboard-message-value']
    # Icon-only in a row, so the tick is its only local acknowledgement.
    assert_equal 1, button.css("[data-clipboard-target='icon']").size
  end

  test 'the toast host sits outside the shell, where nothing can clip it' do
    get story_group_invites_path(@story_group)

    assert_select '#gh-toasts[popover=manual][aria-live=polite]', 1
    assert_select '.gh-shell #gh-toasts', false
  end

  # --- authorization --------------------------------------------------------

  test 'a supporting teacher manages invites too' do
    supporter = FactoryBot.create(:user, role: :teacher)
    FactoryBot.create(:story_group_teacher, story_group: @story_group, user: supporter)
    sign_in_as supporter

    get story_group_invites_path(@story_group)

    assert_response :success
  end

  test 'a student cannot reach invites' do
    student = FactoryBot.create(:user, role: :student)
    FactoryBot.create(:story_group_student, story_group: @story_group, user: student)
    sign_in_as student

    get story_group_invites_path(@story_group)

    # ApplicationController rescues Pundit and bounces to the root rather than
    # confirming the group exists.
    assert_redirected_to root_path
  end
end
