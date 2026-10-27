# frozen_string_literal: true

require 'test_helper'

# Opens every screen in both locales. raise_on_missing_translations is on in
# test, so a missing key fails the render; on top of that an English page must
# not contain Polish letters — a sign of wording that never went through I18n.
class TranslationsTest < ActionDispatch::IntegrationTest
  POLISH_LETTERS = /[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]/

  setup do
    @teacher = create(:user, :teacher, full_name: 'Anna Smith')
    @group   = create(:story_group, owner: @teacher, name: 'Algorithms', currency_name: 'Coins',
                                    ranking_enabled: true,)

    @start_rank = create(:rank, story_group: @group, name: 'Novice', required_currency_value: 0, discount: 0)
    @gold       = create(:rank, story_group: @group, name: 'Gold', required_currency_value: 50, discount: 10)
    @badge      = create(:badge, story_group: @group, name: 'Helper', discount: 5)
    @badge2     = create(:badge, story_group: @group, name: 'Speaker', discount: 7)

    @item = create(:item, story_group: @group, name: 'Retake', price: 40, unlock_rank: @gold,
                          min_rank_for_discount: @start_rank,)
    @item.unlock_badges << @badge
    @item.discount_badges << @badge2
    @cheap = create(:item, story_group: @group, name: 'Hint', price: 1, can_buy_at_0_lives: true)

    @invite   = create(:story_group_invite, story_group: @group)
    @template = create(:activity_group_template, story_group: @group, base_name: 'Lab')
    create(:activity_group_template_category, activity_group_template: @template)
    @sheet    = create(:activity_group, story_group: @group, activity_group_template: @template, name: 'Lab 1')
    @category = create(:activity_group_category, activity_group: @sheet)
    @attendance = create(:activity_group_category, activity_group: @sheet, didactic_description: 'Attendance',
                                                   position:       1,)

    @assistant  = create(:user, :teacher, full_name: 'Bob Brown')
    @assistance = create(:story_group_teacher, story_group: @group, user: @assistant)

    @student    = create(:user, :student, full_name: 'Carl Green')
    @membership = create(:story_group_student, story_group: @group, user: @student, nickname: 'Comet',
                                               lives: 2, current_currency: 30, total_currency: 30,)
    create(:students_activity_group_category, student: @membership, activity_group_category: @category)
    @awarded = create(:students_badge, story_group_student: @membership, badge: @badge)
    create(:students_item, story_group_student: @membership, item: @cheap, price_paid: 1)
    create(:currency_transaction, student: @membership, amount: 10, kind: :reward,
                                  transactionable: @category,)
    create(:currency_transaction, student: @membership, amount: -1, kind: :purchase, transactionable: @cheap)
    CurrencyAdjusterService.new(student: @membership, granted_by_user: @teacher).adjust(3)
    create(:notification, user: @teacher, story_group: @group, story_group_student: @membership, item: @cheap)

    @other_group  = create(:story_group, owner: @teacher, name: 'Databases', currency_name: 'Gems')
    @other_invite = create(:story_group_invite, story_group: @other_group)
  end

  %w[pl en].each do |locale|
    test "teacher screens render in #{locale}" do
      choose(locale)
      sign_in @teacher

      visit_all(locale, teacher_paths)
    end

    test "student screens render in #{locale}" do
      choose(locale)
      sign_in @student

      visit_all(locale, student_paths)
    end

    test "logged-out screens render in #{locale}" do
      choose(locale)

      visit_all(locale, [login_path, new_auth_passwordless_path])

      post auth_passwordless_path, params: { email: 'nobody@example.com' }
      visit_all(locale, [auth_passwordless_inbox_path])
    end

    test "the login e-mail is written in #{locale}" do
      mail = I18n.with_locale(locale) do
        PasswordlessMailer.with(token_link: 'https://example.com/t', email: @student.email,
                                user_name: @student.full_name,).token_email.message
      end

      assert_equal I18n.t('passwordless_mailer.token_email.subject', locale: locale), mail.subject
      assert_no_polish(mail.body.encoded, 'login e-mail') if locale == 'en'
    end

    # The tests below submit forms: a success must leave a translated notice
    # (checked as a string and again on the page it lands on), a rejected form
    # must re-render with translated validation messages.
    test "group settings forms answer in #{locale}" do
      choose(locale)
      sign_in @teacher

      patch story_group_path(@group), params: { story_group: { name: 'Algorithms II' } }
      assert_flash_shown(locale)
      patch story_group_path(@group), params: { story_group: { name: '' } }
      assert_form_rejected(locale)
      post story_groups_path, params: { story_group: { name: '' }, setup: { path: 'custom' } }
      assert_form_rejected(locale)

      patch story_group_ranking_path(@group), params: { story_group: { ranking_enabled: '1', ranking_mode: 'full' } }
      assert_flash_shown(locale)
      patch story_group_ranking_path(@group), params: { story_group: { ranking_enabled: '0' } }
      assert_flash_shown(locale)

      post story_group_teachers_path(@group),
           params: { story_group_teacher: { user_id: create(:user, :teacher, full_name: 'Dana White').id } }
      assert_flash_shown(locale)
      delete story_group_teacher_path(@group, @assistance)
      assert_flash_shown(locale)

      post story_group_invites_path(@group),
           params: { story_group_invite: { limit_enabled: '1', max_uses: '10' } }
      assert_flash_shown(locale)
      post story_group_invites_path(@group),
           params: { story_group_invite: { expiry_enabled: '1', expires_on: '2000-01-01' } }
      assert_form_rejected(locale)
      patch story_group_invite_path(@group, @invite), params: { story_group_invite: { limit_enabled: '0' } }
      assert_flash_shown(locale)
      delete story_group_invite_path(@group, @invite)
      assert_flash_shown(locale)

      delete story_group_path(@group), params: { confirm: 'wrong name' }
      assert_form_rejected(locale)
      delete story_group_path(@group), params: { confirm: @group.reload.name }
      assert_flash_shown(locale)
    end

    test "rank, badge and item forms answer in #{locale}" do
      choose(locale)
      sign_in @teacher

      post story_group_ranks_path(@group), params: { rank: rank_params(name: 'Silver', required_currency_value: 20) }
      assert_flash_shown(locale)
      post story_group_ranks_path(@group), params: { rank: rank_params(name: 'Copy', required_currency_value: 50) }
      assert_form_rejected(locale)
      patch story_group_rank_path(@group, @gold), params: { rank: { name: 'Platinum' } }
      assert_flash_shown(locale)
      delete story_group_rank_path(@group, @gold) # Retake unlocks at this rank, so it is blocked
      assert_flash_shown(locale)

      post story_group_badges_path(@group), params: { badge: badge_params(name: 'Mentor') }
      assert_flash_shown(locale)
      post story_group_badges_path(@group), params: { badge: badge_params(name: '') }
      assert_form_rejected(locale)
      patch story_group_badge_path(@group, @badge), params: { badge: { name: 'Big helper' } }
      assert_flash_shown(locale)
      delete story_group_badge_path(@group, @badge2)
      assert_flash_shown(locale)

      post story_group_items_path(@group), params: { item: item_params(name: 'Pass') }
      assert_flash_shown(locale)
      post story_group_items_path(@group), params: { item: item_params(name: '', price: -1) }
      assert_form_rejected(locale)
      patch story_group_item_path(@group, @item), params: { item: { name: 'Second try' } }
      assert_flash_shown(locale)
      delete story_group_item_path(@group, @item)
      assert_flash_shown(locale)
    end

    test "sheet and grading forms answer in #{locale}" do
      choose(locale)
      sign_in @teacher

      post story_group_activity_group_templates_path(@group), params: {
        activity_group_template: {
          base_name:             'Quiz',
          categories_attributes: { '0' => { didactic_description: 'Score', reward: 5, position: 0 } },
        },
      }
      assert_flash_shown(locale)
      post story_group_activity_group_templates_path(@group),
           params: { activity_group_template: { base_name: 'Empty' } }
      assert_form_rejected(locale)
      patch story_group_activity_group_template_path(@group, @template),
            params: { activity_group_template: { base_name: 'Lab+' } }
      assert_flash_shown(locale)

      post story_group_activity_groups_path(@group),
           params: { activity_group: { activity_group_template_id: @template.id, mode: 'single', name: 'Lab 2' } }
      assert_flash_shown(locale)
      post story_group_activity_groups_path(@group, count: 3),
           params: { activity_group: { activity_group_template_id: @template.id, mode: 'many' } }
      assert_flash_shown(locale)

      grading = story_group_activity_group_students_activity_group_categories_path(@group, @sheet)
      patch grading
      assert_flash_shown(locale)
      patch grading, params: { completions: { @membership.id => { @attendance.id => '1' } } }
      assert_flash_shown(locale)

      delete story_group_activity_group_path(@group, @sheet)
      assert_flash_shown(locale)
      delete story_group_activity_group_template_path(@group, @template)
      assert_flash_shown(locale)
    end

    test "actions on a student answer in #{locale}" do
      choose(locale)
      sign_in @teacher
      student = story_group_student_path(@group, @membership)

      patch student, params: { story_group_student: { lives: 3 } }
      assert_flash_shown(locale)
      patch student, params: { story_group_student: { lives: -1 } }
      assert_form_rejected(locale)
      post update_lives_story_group_student_path(@group, @membership), params: { change: -1 }
      assert_flash_shown(locale)
      patch student, params: { story_group_student: { lives: 0 } }
      post update_lives_story_group_student_path(@group, @membership), params: { change: -1 }
      assert_flash_shown(locale)

      adjustment = story_group_student_currency_adjustment_path(@group, @membership)
      post adjustment, params: { currency_adjustment: { sign: '1', amount: '5' } }
      assert_flash_shown(locale)
      post adjustment, params: { currency_adjustment: { sign: '1', amount: '' } }
      assert_form_rejected(locale)
      post adjustment, params: { currency_adjustment: { sign: '-1', amount: '9999' } }
      assert_form_rejected(locale)

      post story_group_student_badges_path(@group, @membership), params: { students_badge: { badge_id: @badge2.id } }
      assert_flash_shown(locale)
      post story_group_student_badges_path(@group, @membership), params: { students_badge: { badge_id: @badge2.id } }
      assert_form_rejected(locale)
      delete story_group_student_badge_path(@group, @membership, @awarded)
      assert_flash_shown(locale)

      delete student
      assert_flash_shown(locale)
    end

    test "student actions answer in #{locale}" do
      choose(locale)
      sign_in @student

      post buy_story_group_shop_path(@group, @cheap)
      assert_flash_shown(locale)
      post buy_story_group_shop_path(@group, @item) # locked behind the Gold rank and a badge
      assert_flash_shown(locale)

      patch story_group_membership_path(@group), params: { story_group_student: { nickname: 'Rocket' } }
      assert_flash_shown(locale)
      patch story_group_membership_path(@group), params: { story_group_student: { nickname: 'x' * 200 } }
      assert_form_rejected(locale)

      post join_index_path, params: { code: 'NOPE00' }
      assert_form_rejected(locale)
      post join_index_path, params: { code: @other_invite.code }
      follow_redirect!
      assert_response :success
      assert_translated(locale, response.body, 'join done')

      delete story_group_membership_path(@group)
      assert_flash_shown(locale)
    end

    test "sign-in and access alerts are in #{locale}" do
      choose(locale)

      get home_path
      assert_flash_shown(locale)
      get auth_passwordless_verify_path(token: 'bogus')
      assert_flash_shown(locale)
      post auth_passwordless_path, params: { email: @teacher.email }
      post auth_passwordless_path, params: { email: @teacher.email } # only a resend leaves a notice
      assert_flash_shown(locale)

      sign_in @teacher
      get login_path
      assert_flash_shown(locale)
      get story_group_path(id: 0)
      assert_flash_shown(locale)
    end
  end

  test 'a quick-start group is created in the teacher’s language' do
    choose('en')
    sign_in @teacher

    post story_groups_path, params: {
      story_group: { name: 'Physics', currency_name: 'Stars', default_lives: 3 },
      setup:       { path: 'quick', pack: 'scifi', classes: 12 },
    }

    group = StoryGroup.find_by!(name: 'Physics')
    assert_equal %w[Cadet Pilot Navigator Commander Admiral], group.ranks.by_threshold.map(&:name)
    assert_equal 'Classes', group.activity_group_templates.first.base_name
  end

  private

  def choose(locale)
    patch locale_path, params: { locale: locale }
  end

  def visit_all(locale, paths)
    paths.each do |path|
      get path
      assert_response :success, "#{path} (#{locale})"
      assert_select "html[lang=#{locale}]" if response.body.include?('<html')
      assert_no_polish(response.body, path) if locale == 'en'
    end
  end

  # The page after a form action: a plain redirect, or the turbo-stream
  # "redirect" action that redirect_outside_turbo_frame renders.
  def assert_flash_shown(locale)
    where   = "#{request.request_method} #{request.path}"
    message = flash[:notice] || flash[:alert]
    assert message.present?, "no flash after #{where}"
    assert_translated(locale, message, where)

    target = response.redirect? ? response.location : response.body[/action="redirect"[^>]*target="([^"]+)"/, 1]
    flunk "no redirect after #{where}" unless target
    get target
    follow_redirect! while response.redirect?
    assert_response :success, "page after #{where}"
    assert_translated(locale, response.body, "page after #{where}")
  end

  def assert_form_rejected(locale)
    where = "#{request.request_method} #{request.path}"
    assert_response :unprocessable_content, where
    assert_translated(locale, response.body, where)
  end

  def assert_translated(locale, html, where)
    assert_no_match(/translation missing/i, html, "missing translation in #{where}")
    assert_no_polish(html, where) if locale == 'en'
  end

  def rank_params(**attrs)
    { discount: 5, icon_glyph: 'chev1' }.merge(attrs)
  end

  def badge_params(**attrs)
    { didactic_description: 'Helps others', discount: 3, icon_glyph: 'rabbit' }.merge(attrs)
  end

  def item_params(**attrs)
    { didactic_description: 'Skip one task', price: 5, icon_glyph: 'shield' }.merge(attrs)
  end

  def assert_no_polish(html, where)
    text  = Nokogiri::HTML(html).text
    match = text.match(POLISH_LETTERS)
    return pass unless match

    snippet = text[[match.begin(0) - 40, 0].max, 80].squish
    flunk "Polish text left in #{where}: …#{snippet}…"
  end

  def teacher_paths
    [
      home_path,
      story_groups_path,
      new_story_group_path,
      preset_preview_story_groups_path(pack: 'fantasy', classes: 12, currency_name: 'Coins'),
      story_group_path(@group),
      edit_story_group_path(@group),
      confirm_destroy_story_group_path(@group),
      created_story_group_path(@group),
      story_group_students_path(@group),
      *StudentSheet::TABS.map { |tab| story_group_student_path(@group, @membership, tab: tab) },
      edit_story_group_student_path(@group, @membership),
      confirm_destroy_story_group_student_path(@group, @membership),
      story_group_student_students_items_path(@group, @membership),
      new_story_group_student_badge_path(@group, @membership),
      confirm_destroy_story_group_student_badge_path(@group, @membership, @awarded),
      new_story_group_student_currency_adjustment_path(@group, @membership),
      story_group_items_path(@group),
      new_story_group_item_path(@group),
      edit_story_group_item_path(@group, @item),
      confirm_destroy_story_group_item_path(@group, @item),
      story_group_ranks_path(@group),
      new_story_group_rank_path(@group),
      edit_story_group_rank_path(@group, @gold),
      confirm_destroy_story_group_rank_path(@group, @gold),
      story_group_badges_path(@group),
      new_story_group_badge_path(@group),
      edit_story_group_badge_path(@group, @badge),
      confirm_destroy_story_group_badge_path(@group, @badge),
      story_group_invites_path(@group),
      new_story_group_invite_path(@group),
      edit_story_group_invite_path(@group, @invite),
      story_group_invite_path(@group, @invite),
      quick_story_group_invites_path(@group),
      confirm_destroy_story_group_invite_path(@group, @invite),
      story_group_teachers_path(@group),
      new_story_group_teacher_path(@group),
      confirm_destroy_story_group_teacher_path(@group, @assistance),
      story_group_activity_groups_path(@group),
      new_story_group_activity_group_path(@group, template_id: @template.id),
      edit_story_group_activity_group_path(@group, @sheet),
      confirm_destroy_story_group_activity_group_path(@group, @sheet),
      new_story_group_activity_group_template_path(@group),
      edit_story_group_activity_group_template_path(@group, @template),
      confirm_destroy_story_group_activity_group_template_path(@group, @template),
      edit_story_group_activity_group_students_activity_group_categories_path(@group, @sheet),
      story_group_ranking_path(@group),
      confirm_visibility_story_group_ranking_path(@group, enabled: false),
      confirm_mode_story_group_ranking_path(@group, mode: 'full'),
      notifications_path,
    ]
  end

  def student_paths
    [
      home_path,
      story_groups_path,
      story_group_path(@group),
      story_group_shop_index_path(@group),
      confirm_buy_story_group_shop_path(@group, @cheap),
      story_group_student_students_items_path(@group, @membership),
      story_group_student_currency_transactions_path(@group, @membership),
      story_group_badges_path(@group),
      story_group_ranks_path(@group),
      story_group_ranking_path(@group),
      edit_story_group_membership_path(@group),
      nickname_story_group_membership_path(@group),
      confirm_leave_story_group_membership_path(@group),
      new_join_path,
      join_path(code: @other_invite.code),
    ]
  end
end
