# frozen_string_literal: true

require 'test_helper'

# The "Grupy" screen (mockup #/s/groups and #/t/groups), converted to the
# redesign layout. One view, two personas.
class StoryGroupsRedesignSmokeTest < ActionDispatch::IntegrationTest
  # A 1x1 transparent PNG. The app has no fixture files directory and this
  # screen only cares whether an icon is attached, not what is in it.
  PNG = Base64.decode64(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  )

  # A teacher who holds all three roles at once: owns one group, supports a
  # second, learns in a third. Every tab and every role tag on one screen.
  def teacher_in_every_role
    teacher = FactoryBot.create(:user, role: :teacher)

    owned = FactoryBot.create(:story_group, owner: teacher, name: 'Alfa')
    supported = FactoryBot.create(:story_group, name: 'Beta')
    FactoryBot.create(:story_group_teacher, user: teacher, story_group: supported)
    learned = FactoryBot.create(:story_group, name: 'Gamma', currency_name: 'Punktów')
    FactoryBot.create(:story_group_student, user: teacher, story_group: learned, current_currency: 14)

    [teacher, owned, supported, learned]
  end

  # css_select inside an assert_select block is not scoped to the block here,
  # so the card is addressed by its link in one selector instead.
  def card_meta(story_group)
    css_select("article.gh-ixc:has(a[href='#{story_group_path(story_group)}']) .gh-ixmeta span")
      .map(&:text)
  end

  # --- layout ---------------------------------------------------------------

  test 'the group index renders inside the redesign chrome' do
    sign_in FactoryBot.create(:user, role: :teacher)
    get story_groups_path

    assert_response :success
    assert_select '.gh-shell header.gh-hd'
    assert_select 'link[href*=redesign]'
    assert_select 'link[href*=application]', false
    assert_no_match(/data-bs-/, response.body)
  end

  test 'the unconverted actions stay on the Bootstrap layout' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = FactoryBot.create(:story_group, owner: teacher)

    sign_in teacher
    get story_group_path(story_group)

    assert_response :success
    assert_select '.gh-shell', false
    assert_select 'link[href*=application]'
  end

  test 'the sidebar marks Grupy as the current destination' do
    sign_in FactoryBot.create(:user, role: :teacher)
    get story_groups_path

    assert_select 'aside.gh-sb a.gh-nl.gh-nl--on[href=?][aria-current=page]', story_groups_path, 'Grupy'
  end

  # --- tabs -----------------------------------------------------------------

  test 'a user in every role gets three role tabs whose counts sum to the total' do
    teacher, = teacher_in_every_role

    sign_in teacher
    get story_groups_path

    assert_select 'nav.gh-gtabs a.gh-gt2', 4
    assert_select 'a.gh-gt2[href=?]', story_groups_path, /Wszystkie/
    assert_select 'a.gh-gt2[href=?]', story_groups_path(filter: 'mine'), /Moje/
    assert_select 'a.gh-gt2[href=?]', story_groups_path(filter: 'teacher'), /Nauczam/
    assert_select 'a.gh-gt2[href=?]', story_groups_path(filter: 'student'), /Uczę się/

    counts = css_select('a.gh-gt2 .gh-n').map { |node| node.text.to_i }

    assert_equal [3, 1, 1, 1], counts
    assert_equal counts.first, counts.drop(1).sum
  end

  test 'the current tab is the only one marked' do
    teacher, = teacher_in_every_role

    sign_in teacher
    get story_groups_path(filter: 'mine')

    assert_select 'a.gh-gt2[aria-current=true]', 1
    assert_select 'a.gh-gt2[aria-current=true][href=?]', story_groups_path(filter: 'mine')
  end

  test 'a tab that would select everything is not shown at all' do
    teacher = FactoryBot.create(:user, role: :teacher)
    FactoryBot.create(:story_group, owner: teacher, name: 'Alfa')
    FactoryBot.create(:story_group, owner: teacher, name: 'Beta')

    sign_in teacher
    get story_groups_path

    # "Moje" would repeat "Wszystkie" exactly, so only one tab survives and the
    # strip does not render.
    assert_select 'nav.gh-gtabs', false
    assert_select 'article.gh-ixc', 2
  end

  test 'a student gets no tab strip and cannot create a group' do
    student = FactoryBot.create(:user, role: :student)
    FactoryBot.create(:story_group_student, user:        student,
                                            story_group: FactoryBot.create(:story_group, name: 'Alfa'),)

    sign_in student
    get story_groups_path

    assert_response :success
    assert_select 'nav.gh-gtabs', false
    assert_select 'a[href=?]', new_story_group_path, false
    assert_select 'a[href=?]', new_join_path, 'Dołącz do grupy'
  end

  # --- filtering ------------------------------------------------------------

  test 'each filter selects exactly its own role' do
    teacher, owned, supported, learned = teacher_in_every_role

    sign_in teacher

    { 'mine' => owned, 'teacher' => supported, 'student' => learned }.each do |filter, expected|
      get story_groups_path(filter: filter)

      assert_select 'article.gh-ixc', 1
      assert_select 'a.gh-ixc-l[href=?]', story_group_path(expected)
    end
  end

  test 'an unknown filter falls back to every group' do
    teacher, = teacher_in_every_role

    sign_in teacher
    get story_groups_path(filter: 'nonsense')

    assert_select 'article.gh-ixc', 3
    assert_select 'a.gh-gt2[aria-current=true][href=?]', story_groups_path
  end

  # --- cards ----------------------------------------------------------------

  test 'every role gets its own tag and meta line' do
    teacher, owned, supported, learned = teacher_in_every_role
    supported.owner.update!(full_name: 'Janusz Nowakowski')
    FactoryBot.create(:story_group_student, story_group: owned,
                                            user:        FactoryBot.create(:user, role: :student),)

    sign_in teacher
    get story_groups_path

    assert_select "article.gh-ixc:has(a[href='#{story_group_path(owned)}']) .gh-tag.gh-tag--own", 'Prowadzisz'
    assert_equal ['1 student', 'Brak nowych zakupów'], card_meta(owned)

    assert_select "article.gh-ixc:has(a[href='#{story_group_path(supported)}']) .gh-tag.gh-tag--sup", 'Wspierasz'
    assert_equal ['0 studentów', 'Właściciel: Janusz Nowakowski'], card_meta(supported)

    assert_select "article.gh-ixc:has(a[href='#{story_group_path(learned)}']) .gh-tag.gh-tag--lrn", 'Uczysz się'
    assert_equal ['1 student', 'Masz 14 Punktów'], card_meta(learned)
  end

  test 'an owner sees how many purchases landed in the last two days' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = FactoryBot.create(:story_group, owner: teacher, name: 'Alfa')
    membership = FactoryBot.create(:story_group_student, story_group: story_group,
                                                         user:        FactoryBot.create(:user, role: :student),)
    item = FactoryBot.create(:item, story_group: story_group)

    2.times { CurrencyTransaction.create!(student: membership, amount: -5, kind: :purchase, transactionable: item) }
    CurrencyTransaction.create!(student: membership, amount: -5, kind: :purchase, transactionable: item,
                                created_at: 3.days.ago,)
    CurrencyTransaction.create!(student: membership, amount: 10, kind: :reward)

    sign_in teacher
    get story_groups_path

    # Two, not four: the older purchase is outside the window and a reward is
    # not a purchase.
    assert_select '.gh-ixmeta span', '2 nowe zakupy'
  end

  # --- artwork --------------------------------------------------------------

  test 'a group without artwork falls back to a monogram of its long words' do
    teacher = FactoryBot.create(:user, role: :teacher)
    FactoryBot.create(:story_group, owner: teacher, name: 'Wstęp do algorytmiki szkolnej')

    sign_in teacher
    get story_groups_path

    assert_select '.gh-art.gh-art--mono', 'WA'
    assert_select '.gh-art img', false
  end

  test 'a group with artwork shows it instead of the monogram' do
    teacher = FactoryBot.create(:user, role: :teacher)
    story_group = FactoryBot.create(:story_group, owner: teacher, name: 'Alfa')
    story_group.icon.attach(io: StringIO.new(PNG), filename: 'icon.png', content_type: 'image/png')

    sign_in teacher
    get story_groups_path

    assert_select '.gh-art img'
    assert_select '.gh-art--mono', false
  end

  # --- search ---------------------------------------------------------------

  test 'the grid is wired for client-side search' do
    teacher, owned, = teacher_in_every_role

    sign_in teacher
    get story_groups_path

    assert_select '[data-controller=group-search]' do
      assert_select 'input[type=search][data-action=?]', 'input->group-search#filter'
      assert_select 'article.gh-ixc[data-group-search-target=card]', 3
      assert_select 'article[data-group-search-name=?]', owned.name.downcase
      assert_select '.gh-gm[hidden][data-group-search-target=empty]'
    end
  end

  # --- empty states ---------------------------------------------------------

  test 'a user with no groups gets the empty panel and no search bar' do
    sign_in FactoryBot.create(:user, role: :teacher)
    get story_groups_path

    assert_select '.gh-gm h2', 'Nie masz jeszcze żadnej grupy'
    assert_select 'input[type=search]', false
    assert_select 'article.gh-ixc', false
  end
end
