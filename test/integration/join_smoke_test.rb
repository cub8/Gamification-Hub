# frozen_string_literal: true

require 'test_helper'

# Joining a group: the mockup's three-step flow (code -> pseudonim -> done),
# in the shared modal and as the full page a QR scan lands on.
class JoinSmokeTest < ActionDispatch::IntegrationTest
  MODAL = { 'Turbo-Frame' => 'modal' }.freeze

  setup do
    @owner = FactoryBot.create(:user, role: :teacher, full_name: 'Janusz Nowakowski')
    @story_group = FactoryBot.create(:story_group, owner: @owner, name: 'Zakon Algorytmów',
                                                   currency_name: 'Klejnoty',)
    @invite = FactoryBot.create(:story_group_invite, story_group: @story_group)
    @user = FactoryBot.create(:user, role: :student, full_name: 'Sebastian Alejandro')
    sign_in @user
  end

  def join(nickname: nil, code: nil)
    post join_index_path, params: { code: code || @invite.code, nickname: nickname }, headers: MODAL
  end

  # --- invite codes ---------------------------------------------------------

  test 'a generated code is six characters with no confusable letters' do
    codes = Array.new(30) { FactoryBot.create(:story_group_invite).code }

    codes.each do |code|
      assert_equal 6, code.length
      assert_match(/\A[A-Z2-9]{6}\z/, code)
      assert_no_match(/[O0I1L]/, code, "#{code} contains a character that is easy to misread")
    end
  end

  test 'a code issued before the six-character rule still resolves' do
    legacy = FactoryBot.create(:story_group_invite, story_group: @story_group, code: '7oCowSqfz9w=')

    get lookup_join_index_path(code: legacy.code), headers: MODAL

    assert_response :success
    assert_select 'h2', 'Dołączasz do grupy Zakon Algorytmów'
  end

  # --- step 1 ---------------------------------------------------------------

  test 'step 1 asks for six characters and submits one hidden value' do
    get new_join_path, headers: MODAL

    assert_response :success
    assert_select 'turbo-frame#modal', 1
    assert_select '[data-controller=join-code]' do
      assert_select 'input[data-join-code-target=slot]', 6
      assert_select 'input[type=hidden][name=code][data-join-code-target=code]'
      assert_select 'button[type=submit][data-join-code-target=submit]', 'Dalej'
    end
  end

  test 'a step rendered in the modal ships exactly one frame with that id' do
    get new_join_path, headers: MODAL

    # The layout carries a <turbo-frame id="modal"> of its own inside the
    # dialog, so rendering it here too would give Turbo two to choose from.
    assert_select 'turbo-frame#modal', 1
    assert_select 'header.gh-hd', false
  end

  test 'an unknown code comes back on step 1 with its own message' do
    get lookup_join_index_path(code: 'ZZZZZZ'), headers: MODAL

    assert_response :unprocessable_content
    assert_select '.gh-err span', 'Nie znaleźliśmy takiego kodu. Sprawdź go z prowadzącym.'
    assert_select 'input[data-join-code-target=slot]', 6
  end

  test 'an expired code says so rather than just failing' do
    @invite.update!(expires_at: 1.hour.ago)

    get lookup_join_index_path(code: @invite.code), headers: MODAL

    assert_response :unprocessable_content
    assert_select '.gh-err span', 'Ten kod wygasł. Poproś prowadzącego o nowy.'
  end

  test 'a code that ran out of seats gets its own message' do
    @invite.update!(uses: 10, max_uses: 10)

    get lookup_join_index_path(code: @invite.code), headers: MODAL

    assert_response :unprocessable_content
    assert_select '.gh-err span', /maksymalna liczba osób/
  end

  test 'already belonging to the group is a way in, not an error' do
    FactoryBot.create(:story_group_student, user: @user, story_group: @story_group)

    get lookup_join_index_path(code: @invite.code), headers: MODAL

    assert_response :unprocessable_content
    assert_select '.gh-err', false
    assert_select '.gh-hint a[href=?]', story_group_path(@story_group), 'Otwórz grupę'
  end

  # --- step 2 ---------------------------------------------------------------

  test 'a good code moves on to the nickname step' do
    get lookup_join_index_path(code: @invite.code), headers: MODAL

    assert_response :success
    assert_select 'h2', 'Dołączasz do grupy Zakon Algorytmów'
    assert_select 'input[type=hidden][name=code][value=?]', @invite.code
    assert_select 'input[name=nickname]'
    assert_select 'button[type=submit]', 'Dołącz do grupy'
  end

  test 'the nickname field says it may be left blank' do
    get lookup_join_index_path(code: @invite.code), headers: MODAL

    # Deliberately unlike the mockup, which makes the nickname mandatory.
    assert_select '.gh-hint', /Zostaw puste/
    assert_select 'input[name=nickname][required]', false
    assert_select 'button[type=submit][disabled]', false
  end

  # --- joining --------------------------------------------------------------

  test 'a nickname is stored and shown' do
    assert_difference('StoryGroupStudent.count') do
      join(nickname: 'Kapitan Uszatek')
    end

    membership = StoryGroupStudent.last

    assert_equal 'Kapitan Uszatek', membership.nickname
    assert_equal 'Kapitan Uszatek', membership.display_name
    assert_select 'b', 'Kapitan Uszatek'
  end

  test 'a blank nickname means the real name, not a blank one' do
    assert_difference('StoryGroupStudent.count') do
      join(nickname: '   ')
    end

    membership = StoryGroupStudent.last

    assert_nil membership.nickname
    assert_equal 'Sebastian Alejandro', membership.display_name
    assert_select 'b', 'Sebastian Alejandro'
  end

  test 'a nickname already taken in the group is refused, whatever its case' do
    FactoryBot.create(:story_group_student, story_group: @story_group,
                                            user:        FactoryBot.create(:user, role: :student),
                                            nickname:    'Nova',)

    assert_no_difference('StoryGroupStudent.count') do
      join(nickname: 'nOvA')
    end

    assert_response :unprocessable_content
    assert_select '.gh-inp--bad input[name=nickname]'
    assert_select '.gh-err span'
  end

  test 'the same nickname in a different group is fine' do
    other = FactoryBot.create(:story_group, owner: @owner)
    FactoryBot.create(:story_group_student, story_group: other,
                                            user:        FactoryBot.create(:user, role: :student),
                                            nickname:    'Nova',)

    assert_difference('StoryGroupStudent.count') do
      join(nickname: 'Nova')
    end

    assert_response :success
  end

  test 'joining spends one use of the invite' do
    assert_difference -> { @invite.reload.uses }, 1 do
      join
    end
  end

  # --- step 3 ---------------------------------------------------------------

  test 'the confirmation names the group, its owner and its currency' do
    join(nickname: 'Nova')

    assert_select 'h2', 'Dołączono do grupy Zakon Algorytmów'
    assert_select 'p', /Prowadzi Janusz Nowakowski\./
    assert_select 'p', /Walutą w tej grupie są Klejnoty\./
  end

  test 'Gotowe leaves the dialog for the group itself' do
    join

    assert_select '.gh-dlg-b a[href=?][data-turbo-frame=_top]', story_group_path(@story_group), 'Gotowe'
  end

  # --- the QR landing page --------------------------------------------------

  test 'a scanned code lands on the nickname step as a full page' do
    get join_path(code: @invite.code)

    assert_response :success
    # The layout always carries one modal frame in its dialog; what matters is
    # that the step rendered as page content rather than inside it.
    assert_select 'main.gh-auth turbo-frame#modal', false
    # The focused, navigation-less shell: no chrome to distract from one task.
    assert_select 'main.gh-auth .gh-acard'
    assert_select 'header.gh-hd', false
    assert_select 'h2', 'Dołączasz do grupy Zakon Algorytmów'
  end

  test 'the page variant offers a way back instead of a dialog close button' do
    get join_path(code: @invite.code)

    assert_select 'a.gh-btn--sec[href=?]', home_path, 'Anuluj'
    assert_select '[data-action=?]', 'dialog#close', false
  end

  test 'a scanned code that is no good falls back to step 1 on the page' do
    get join_path(code: 'ZZZZZZ')

    assert_response :unprocessable_content
    assert_select 'main.gh-auth input[data-join-code-target=slot]', 6
    assert_select '.gh-err span', 'Nie znaleźliśmy takiego kodu. Sprawdź go z prowadzącym.'
  end

  # --- chrome ---------------------------------------------------------------

  test 'both roles can reach the join dialog from the header' do
    [@user, FactoryBot.create(:user, role: :teacher)].each do |user|
      sign_out
      sign_in user
      get home_path

      assert_select '.gh-hd a.gh-hd-join[href=?][data-turbo-frame=modal]', new_join_path
    end
  end
end
