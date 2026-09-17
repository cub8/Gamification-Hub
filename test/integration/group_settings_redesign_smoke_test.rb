# frozen_string_literal: true

require 'test_helper'

# The two settings screens, converted to the redesign layout: the teacher's
# "Ustawienia grupy" (mockup #/t/group-settings) and the student's "Ustawienia
# w grupie" (#/s/group-settings).
#
# One record, two screens, and the line between them is what most of this is
# about — a teacher has no membership to edit, a student may not touch the
# group, and only the OWNER may delete it (DECISIONS.md:40).
class GroupSettingsRedesignSmokeTest < ActionDispatch::IntegrationTest
  # A 1x1 transparent PNG. These screens only care whether an icon is attached,
  # not what is in it.
  PNG = Base64.decode64(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  )

  def group(**attrs)
    FactoryBot.create(:story_group,
                      { name: 'Kosmiczne króliki', currency_name: 'Marchewek' }.merge(attrs),)
  end

  def owner_of(story_group)
    story_group.owner.tap { |owner| owner.update!(role: :teacher) }
  end

  def student_in(story_group, **attrs)
    FactoryBot.create(:story_group_student,
                      {
                        story_group: story_group,
                        user:        FactoryBot.create(:user, role:      :student,
                                                              full_name: 'Sebastian Alejandro',),
                        lives:       3,
                      }.merge(attrs),)
  end

  # The settings form posts every field at once, so a partial update would look
  # like a pass while quietly dropping the rest.
  def settings_params(**overrides)
    {
      story_group: {
        name:                'Nowa nazwa',
        description:         'Galaktyka jest wielka.',
        icon_glyph:          'waves',
        currency_name:       'Punktów',
        currency_icon_glyph: 'gem',
        default_lives:       5,
      }.merge(overrides),
    }
  end

  # --- teacher: layout ------------------------------------------------------

  test 'the settings page renders inside the redesign chrome' do
    story_group = group
    sign_in owner_of(story_group)
    get edit_story_group_path(story_group)

    assert_response :success
    assert_select '.gh-shell header.gh-hd'
    assert_select 'link[href*=redesign]'
    assert_select 'link[href*=application]', false
    assert_no_match(/data-bs-/, response.body)
  end

  test 'the settings page is a page, not the dialog it used to be' do
    story_group = group
    sign_in owner_of(story_group)
    get edit_story_group_path(story_group)

    # The old screen wrapped itself in the shared modal frame. A page must not:
    # the layout already carries one inside its <dialog>.
    assert_select 'turbo-frame#modal form', false
    assert_select '.gh-wbar button[type=submit]', 'Zapisz zmiany'
  end

  test 'the sidebar marks Ustawienia grupy as the current destination' do
    story_group = group
    sign_in owner_of(story_group)
    get edit_story_group_path(story_group)

    assert_select 'aside.gh-sb a.gh-nl.gh-nl--on[href=?][aria-current=page]',
                  edit_story_group_path(story_group), 'Ustawienia grupy'
  end

  test 'the overview links to settings as a page rather than into the dialog' do
    story_group = group
    sign_in owner_of(story_group)
    get story_group_path(story_group)

    assert_select ".gh-hero a[href='#{edit_story_group_path(story_group)}']" do |links|
      assert_nil links.first['data-turbo-frame']
    end
  end

  # --- teacher: the pickers -------------------------------------------------

  test 'the graphic picker offers every group preset, named in Polish' do
    story_group = group(icon_glyph: 'tables')
    sign_in owner_of(story_group)
    get edit_story_group_path(story_group)

    tiles = css_select('.gh-pz-grid--group .gh-pz input[type=radio]')

    # Five presets plus the upload tile, whose value is the empty string.
    assert_equal([*Redesign::GroupArt::KEYS, ''], tiles.map { |tile| tile['value'] })
    assert_select '.gh-pz-grid--group input[aria-label=?]', 'Grafika grupy: Zamek'
    assert_select '.gh-pz-grid--group input[value=tables][checked]'
    # Scenes carry their own palette, so they are <img>, not inlined glyphs.
    assert_select '.gh-pz-grid--group .gh-pz img'
  end

  test 'the currency picker offers every coin preset, named in Polish' do
    story_group = group(currency_icon_glyph: 'pearl')
    sign_in owner_of(story_group)
    get edit_story_group_path(story_group)

    tiles = css_select('.gh-pz-grid--currency .gh-pz input[type=radio]')

    assert_equal([*Redesign::CurrencyIcons::KEYS, ''], tiles.map { |tile| tile['value'] })
    assert_select '.gh-pz-grid--currency input[aria-label=?]', 'Ikona waluty: Marchewka'
    assert_select '.gh-pz-grid--currency input[value=pearl][checked]'
    # Marks are inlined, so currentColor can tint them on the cream coin face.
    assert_select '.gh-pz-grid--currency .gh-pz svg.gh-cmark'
  end

  test 'both pickers are radio groups and the upload tile is hidden until there is one' do
    story_group = group
    sign_in owner_of(story_group)
    get edit_story_group_path(story_group)

    assert_select '.gh-pz-grid[role=radiogroup][aria-label=?]', 'Gotowe grafiki'
    assert_select '.gh-pz-grid[role=radiogroup][aria-label=?]', 'Gotowe ikony'
    assert_select '.gh-pz--own[hidden]', 2
  end

  test 'an upload reveals its own tile and deselects the preset' do
    story_group = group(icon_glyph: nil)
    story_group.icon.attach(io: StringIO.new(PNG), filename: 'icon.png', content_type: 'image/png')

    sign_in owner_of(story_group)
    get edit_story_group_path(story_group)

    assert_select '.gh-pz-grid--group .gh-pz--own:not([hidden]) input[checked]'
    assert_select '.gh-pz-grid--group .gh-pz--own img[src]'
  end

  # --- teacher: saving ------------------------------------------------------

  test 'saving writes every field and comes back to the settings page' do
    story_group = group
    sign_in owner_of(story_group)
    patch story_group_path(story_group), params: settings_params

    assert_redirected_to edit_story_group_path(story_group)
    assert_equal 'Zapisano ustawienia grupy.', flash[:notice]

    story_group.reload

    assert_equal 'Nowa nazwa', story_group.name
    assert_equal 'Galaktyka jest wielka.', story_group.description
    assert_equal 'waves', story_group.icon_glyph
    assert_equal 'Punktów', story_group.currency_name
    assert_equal 'gem', story_group.currency_icon_glyph
    assert_equal 5, story_group.default_lives
  end

  test 'an empty preset key means the upload is the art' do
    story_group = group(icon_glyph: 'waves')
    sign_in owner_of(story_group)
    patch story_group_path(story_group), params: settings_params(icon_glyph: '')

    # NULL, not "", is how the record says "use my upload".
    assert_nil story_group.reload.icon_glyph
  end

  test 'a file in the submission wins over whatever the picker says' do
    story_group = group
    sign_in owner_of(story_group)
    patch story_group_path(story_group),
          params: settings_params(
            icon_glyph: 'waves',
            icon:       Rack::Test::UploadedFile.new(StringIO.new(PNG), 'image/png',
                                                     true, original_filename: 'icon.png',),
          )

    story_group.reload

    assert_predicate story_group.icon, :attached?
    assert_nil story_group.icon_glyph
  end

  test 'a blank name is refused and says so on the field' do
    story_group = group
    sign_in owner_of(story_group)
    patch story_group_path(story_group), params: settings_params(name: '')

    assert_response :unprocessable_content
    assert_equal 'Kosmiczne króliki', story_group.reload.name
    assert_select '.gh-inp--bad input[name=?]', 'story_group[name]'
    assert_select '.gh-err[role=alert] span', 'Podaj nazwę grupy.'
  end

  test 'an unknown preset key is refused rather than stored' do
    story_group = group
    sign_in owner_of(story_group)
    patch story_group_path(story_group), params: settings_params(icon_glyph: 'rabbits')

    assert_response :unprocessable_content
    assert_nil story_group.reload.icon_glyph
    assert_select '.gh-err[role=alert] span', 'Nieznana grafika.'
  end

  # --- teacher: who may do what --------------------------------------------

  test 'a supporting teacher may change the settings but not delete the group' do
    story_group = group
    supporting = FactoryBot.create(:user, role: :teacher)
    FactoryBot.create(:story_group_teacher, user: supporting, story_group: story_group)

    sign_in supporting
    get edit_story_group_path(story_group)

    assert_response :success
    # DECISIONS.md:40 — everything except deleting the group.
    assert_select '.gh-wbar button[type=submit]'
    assert_select '.gh-danger', false
    assert_select "a[href='#{confirm_destroy_story_group_path(story_group)}']", false

    patch story_group_path(story_group), params: settings_params

    assert_redirected_to edit_story_group_path(story_group)
    assert_equal 'Nowa nazwa', story_group.reload.name
  end

  test 'a supporting teacher cannot reach the delete confirmation directly' do
    story_group = group
    supporting = FactoryBot.create(:user, role: :teacher)
    FactoryBot.create(:story_group_teacher, user: supporting, story_group: story_group)

    sign_in supporting
    get confirm_destroy_story_group_path(story_group)

    assert_redirected_to root_path
  end

  test 'the owner gets the danger panel' do
    story_group = group
    sign_in owner_of(story_group)
    get edit_story_group_path(story_group)

    assert_select '.gh-panel.gh-danger h2', 'Usuń grupę'
    assert_select ".gh-danger a[href='#{confirm_destroy_story_group_path(story_group)}'][data-turbo-frame=modal]"
  end

  test 'a student of the group cannot open its settings' do
    story_group = group
    student = student_in(story_group).user

    sign_in student
    get edit_story_group_path(story_group)

    assert_redirected_to root_path
  end

  # --- teacher: deleting ----------------------------------------------------

  test 'the delete confirmation counts who loses access and asks for the name' do
    story_group = group
    2.times { student_in(story_group, user: FactoryBot.create(:user, role: :student)) }
    FactoryBot.create(:story_group_teacher, user:        FactoryBot.create(:user, role: :teacher),
                                            story_group: story_group,)

    sign_in owner_of(story_group)
    get confirm_destroy_story_group_path(story_group), headers: { 'Turbo-Frame' => 'modal' }

    assert_response :success
    assert_select 'turbo-frame#modal'
    assert_select 'h2.gh-h2', 'Usunąć grupę na zawsze?'
    # Two supporting-or-owning teachers: the list holds one, the owner is held
    # separately and loses access just the same.
    assert_match(/2 studenci i 2 nauczycieli stracą dostęp/, response.body.gsub(/\s+/, ' '))
    assert_select 'form[data-controller=confirm-name][data-confirm-name-expected-value=?]',
                  'Kosmiczne króliki'
    assert_select 'input[name=confirm][data-confirm-name-target=input]'
    assert_select 'button[type=submit][disabled][data-confirm-name-target=submit]', 'Usuń grupę'
  end

  test 'the confirmation opens as a page when it is not in a frame' do
    story_group = group
    sign_in owner_of(story_group)
    get confirm_destroy_story_group_path(story_group)

    assert_response :success
    assert_select '.gh-shell .gh-panel.gh-dlg-page h2.gh-h2', 'Usunąć grupę na zawsze?'
    assert_select 'turbo-frame#modal h2', false
  end

  test 'the typed name is checked on the server, not only in the browser' do
    story_group = group

    sign_in owner_of(story_group)

    assert_no_difference('StoryGroup.count') do
      delete story_group_path(story_group), params: { confirm: 'kosmiczne króliki' }
    end

    # Case-sensitive on purpose: the point is to make you read the name.
    assert_response :unprocessable_content
    assert_select '.gh-err[role=alert] span', /nie zgadza się z nazwą grupy/
  end

  test 'a delete with no confirmation at all is refused' do
    story_group = group

    sign_in owner_of(story_group)

    assert_no_difference('StoryGroup.count') do
      delete story_group_path(story_group)
    end

    assert_response :unprocessable_content
  end

  test 'the exact name deletes the group and everything hanging off it' do
    story_group = group
    student_in(story_group)
    FactoryBot.create(:rank, story_group: story_group)

    sign_in owner_of(story_group)

    assert_difference(['StoryGroup.count', 'StoryGroupStudent.count', 'Rank.count'], -1) do
      delete story_group_path(story_group), params: { confirm: 'Kosmiczne króliki' }
    end

    assert_redirected_to story_groups_path
    assert_equal 'Usunięto grupę Kosmiczne króliki.', flash[:notice]
  end

  # --- student: the screen --------------------------------------------------

  test 'the student settings page renders inside the redesign chrome' do
    story_group = group
    sign_in student_in(story_group).user
    get edit_story_group_membership_path(story_group)

    assert_response :success
    assert_select '.gh-shell header.gh-hd'
    assert_select 'link[href*=application]', false
    assert_select 'h1.gh-h1', 'Ustawienia w grupie'
    assert_select '.gh-crumbs a[href=?]', story_group_path(story_group), 'Kosmiczne króliki'
    assert_select '.gh-lead', 'Te ustawienia dotyczą tylko grupy Kosmiczne króliki.'
  end

  test 'the sidebar carries the student settings entry and marks it current' do
    story_group = group
    sign_in student_in(story_group).user
    get edit_story_group_membership_path(story_group)

    assert_select 'aside.gh-sb a.gh-nl.gh-nl--on[href=?][aria-current=page]',
                  edit_story_group_membership_path(story_group), 'Ustawienia w grupie'
  end

  test 'what the teacher sees is three rows and says nothing about the balance' do
    story_group = group
    student = student_in(story_group, current_currency: 120)
    student.user.update!(university_number: '123456')

    sign_in student.user
    get edit_story_group_membership_path(story_group)

    rows = css_select('.gh-seeing li').map { |row| row.text.split.join(' ') }

    assert_equal ['Imię i nazwisko Sebastian Alejandro',
                  "E-mail #{student.email}",
                  'Numer indeksu 123456',], rows
    # The mockup has a fourth row for currency, badges, items and history; it is
    # deliberately left out.
    assert_no_match(/Waluta, odznaki/, response.body)
  end

  test 'a student with no index number is told so rather than shown a blank' do
    story_group = group
    student = student_in(story_group)
    student.user.update!(university_number: nil)

    sign_in student.user
    get edit_story_group_membership_path(story_group)

    assert_select '.gh-seeing li:last-child b', 'Brak'
  end

  # --- student: the nickname ------------------------------------------------

  test 'the nickname saves and is confirmed by name' do
    story_group = group
    student = student_in(story_group, nickname: 'Kadet')

    sign_in student.user
    patch story_group_membership_path(story_group),
          params: { story_group_student: { nickname: 'Uszaty Pilot' } }

    assert_redirected_to edit_story_group_membership_path(story_group)
    assert_equal 'Twój pseudonim w tej grupie: Uszaty Pilot.', flash[:notice]
    assert_equal 'Uszaty Pilot', student.reload.nickname
  end

  test 'a nickname already taken in this group is refused, whatever the case' do
    story_group = group
    student_in(story_group, user: FactoryBot.create(:user, role: :student), nickname: 'Pilot')
    mine = student_in(story_group, nickname: 'Kadet')

    sign_in mine.user
    patch story_group_membership_path(story_group),
          params: { story_group_student: { nickname: 'pILOT' } }

    assert_response :unprocessable_content
    assert_equal 'Kadet', mine.reload.nickname
    assert_select '.gh-inp--bad input[name=?]', 'story_group_student[nickname]'
    assert_select '.gh-err[role=alert] span', 'Ten pseudonim jest już zajęty w tej grupie.'
  end

  test 'the same nickname in another group is fine' do
    mine = student_in(group, nickname: 'Kadet')
    student_in(group(name: 'Atlantyda'), user:     FactoryBot.create(:user, role: :student),
                                         nickname: 'Pilot',)

    sign_in mine.user
    patch story_group_membership_path(mine.story_group),
          params: { story_group_student: { nickname: 'Pilot' } }

    assert_equal 'Pilot', mine.reload.nickname
  end

  test 'a blank nickname is allowed and falls back to the real name' do
    story_group = group
    mine = student_in(story_group, nickname: 'Kadet')

    sign_in mine.user
    patch story_group_membership_path(story_group),
          params: { story_group_student: { nickname: '' } }

    assert_redirected_to edit_story_group_membership_path(story_group)
    assert_nil mine.reload.nickname
    assert_equal 'Sebastian Alejandro', mine.display_name
  end

  test 'the form cannot reach anything but the nickname' do
    story_group = group
    mine = student_in(story_group, lives: 3, current_currency: 10)

    sign_in mine.user
    patch story_group_membership_path(story_group),
          params: { story_group_student: { nickname: 'Kadet', lives: 99, current_currency: 9999 } }

    mine.reload

    assert_equal 3, mine.lives
    assert_equal 10, mine.current_currency
  end

  # --- student: leaving -----------------------------------------------------

  test 'the leave confirmation counts what goes and does not promise it back' do
    story_group = group
    mine = student_in(story_group, current_currency: 120)
    badge = FactoryBot.create(:badge, story_group: story_group)
    StudentsBadge.create!(story_group_student: mine, badge: badge)

    sign_in mine.user
    get confirm_leave_story_group_membership_path(story_group), headers: { 'Turbo-Frame' => 'modal' }

    assert_response :success
    assert_select 'turbo-frame#modal h2.gh-h2', 'Opuścić grupę Kosmiczne króliki?'
    assert_match(/120 Marchewek, 1 odznaka i 0 przedmiotów/, response.body.gsub(/\s+/, ' '))
    assert_select '.gh-warn[role=alert] span', /Tego nie da się cofnąć/
    # DECISIONS.md:44 wants rejoining to restore everything; ours is a hard
    # delete, so the dialog must not say that.
    assert_no_match(/wszystko wróci|Nic nie przepada/, response.body)
  end

  test 'the safe button is the one you land on' do
    story_group = group
    sign_in student_in(story_group).user
    get confirm_leave_story_group_membership_path(story_group), headers: { 'Turbo-Frame' => 'modal' }

    assert_select '.gh-dlg-b button[autofocus][data-action=?]', 'dialog#close', 'Zostań w grupie'
  end

  test 'leaving destroys the membership and everything hanging off it' do
    story_group = group
    mine = student_in(story_group)
    badge = FactoryBot.create(:badge, story_group: story_group)
    StudentsBadge.create!(story_group_student: mine, badge: badge)
    CurrencyTransaction.create!(student: mine, amount: 10, kind: :reward)

    sign_in mine.user

    assert_difference(['StoryGroupStudent.count', 'StudentsBadge.count', 'CurrencyTransaction.count'],
                      -1,) do
      delete story_group_membership_path(story_group)
    end

    assert_redirected_to story_groups_path
    assert_equal 'Opuszczono grupę Kosmiczne króliki.', flash[:notice]
    # The group itself is untouched — this is one person leaving, not a delete.
    assert_predicate StoryGroup.where(id: story_group.id), :exists?
  end

  test 'a teacher of the group has no membership to settle' do
    story_group = group
    sign_in owner_of(story_group)
    get edit_story_group_membership_path(story_group)

    # 404, turned into a redirect by ApplicationController: this screen is not
    # theirs, and saying "forbidden" would imply there is something here.
    assert_redirected_to root_path
  end

  test 'a student of another group cannot reach this one' do
    story_group = group
    outsider = student_in(group(name: 'Atlantyda'),
                          user: FactoryBot.create(:user, role: :student),).user

    sign_in outsider
    get edit_story_group_membership_path(story_group)

    assert_redirected_to root_path
  end

  test 'one student cannot make another leave' do
    story_group = group
    student_in(story_group, user: FactoryBot.create(:user, role: :student))
    mine = student_in(story_group)

    sign_in mine.user

    # There is no id in the route at all — the membership comes from the
    # session — so the only membership this can destroy is the caller's own.
    assert_difference('StoryGroupStudent.count', -1) do
      delete story_group_membership_path(story_group)
    end

    assert_predicate StoryGroupStudent.where(id: mine.id), :empty?
  end
end
