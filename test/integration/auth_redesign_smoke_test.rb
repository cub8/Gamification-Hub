# frozen_string_literal: true

require 'test_helper'

class AuthRedesignSmokeTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  test 'login page renders on the redesign layout' do
    get login_path
    assert_response :success
    assert_select 'link[href*=redesign]'
    assert_select 'script[src*=redesign]'
    assert_select 'main.gh-auth'
    assert_select 'section.gh-panel.gh-acard'
    assert_select 'h1.gh-h1', 'Zaloguj się'
    assert_select 'p.gh-lead'
    assert_select 'p.gh-who', 2
    assert_select '.gh-or', 'albo'
    assert_select 'button.gh-btn', /Zaloguj się przez USOS/
    assert_select 'a.gh-btn.gh-btn--sec', /Zaloguj się e-mailem/
    assert_select 'i.fa-solid.fa-graduation-cap'
    assert_select 'i.fa-solid.fa-envelope'
    assert_select 'dialog.gh-dialog turbo-frame#modal'
    # No Bootstrap on this page any more.
    assert_select 'link[href*=application]', false
    assert_no_match(/data-bs-/, response.body)
  end

  test 'email login page renders and posts to the right place' do
    get new_auth_passwordless_path
    assert_response :success
    assert_select 'h1.gh-h1', 'Logowanie e-mailem'
    # The label lives in its own span so the underline lands on the text only,
    # not on the chevron (the icon is a flex item and would inherit it).
    assert_select 'a.gh-back > span', 'Inne sposoby logowania'
    assert_select 'a.gh-back > i.fa-solid.fa-chevron-left'
    assert_select 'form[action=?][method=post]', auth_passwordless_path
    assert_select '.gh-fld label[for=email]', 'Adres e-mail'
    assert_select '.gh-inp input#email[name=email][type=email][required]'
    # Must be a <button>, not <input>: the edge is a ::before.
    assert_select 'button.gh-btn[type=submit]', 'Wyślij link'
    assert_select 'input[type=submit]', false
  end

  test 'theme attribute follows the cookie' do
    get login_path
    assert_select 'html:not([data-gh-theme])'

    cookies[:gh_theme] = 'dark'
    get login_path
    assert_select 'html[data-gh-theme=dark]'
  end

  # --- the register line, restored on both login screens -------------------

  test 'both login screens offer registration as an inert button' do
    [login_path, new_auth_passwordless_path].each do |path|
      get path
      assert_response :success
      assert_select 'p.gh-alt', /Nie masz konta\?/
      assert_select 'p.gh-alt button.gh-linkbtn', 'Zarejestruj się'
      # Never a dead link: a nil/# href is the bug this replaced.
      assert_select 'p.gh-alt a', false
    end
  end

  # An ALERT, deliberately: notices rise as toasts now and have no dismiss
  # button to wire. The inline plate is what an error still gets, and it is the
  # error that must not fade on a timer.
  test 'a flash alert is fully wired for dismissal' do
    get auth_passwordless_verify_path(token: 'nie-ma-takiego')
    follow_redirect!

    assert_select '.gh-plate', /Nieprawidłowy token/

    # The bug this pins: the close button dispatched flash#dismiss but nothing
    # carried data-controller="flash", so the action had no controller to reach.
    assert_select '#flash-messages[data-controller=flash]' do
      assert_select '[data-flash-target=message]' do
        assert_select 'button.gh-close[data-action=?]', 'flash#dismiss' do
          assert_select 'i.fa-solid.fa-xmark'
        end
      end
    end
    # The close control must not be the underlined link style.
    assert_select 'button.gh-close.gh-linkbtn', false
  end

  test 'a notice rises as a toast instead of sitting in the content' do
    user = FactoryBot.create(:user)
    post auth_passwordless_path, params: { email: user.email }
    travel 61.seconds do
      post auth_passwordless_path, params: { email: user.email }
      follow_redirect!
    end

    assert_select '#gh-toasts[data-controller=toast] template[data-toast-target=seed]',
                  'Wysłaliśmy nowy link. Poprzedni już nie działa.'
    assert_select '#flash-messages', false
  end

  test 'the table pattern layer is present' do
    get login_path
    assert_select 'div.gh-tpat[aria-hidden=true]'
  end

  test 'footer offers the theme toggle and help' do
    get login_path
    assert_select '.gh-foot button.gh-linkbtn', 'Ciemny motyw'
    assert_select '.gh-foot', /Pomoc:/

    cookies[:gh_theme] = 'dark'
    get login_path
    assert_select '.gh-foot button.gh-linkbtn', 'Jasny motyw'
  end

  # --- the inbox screen ----------------------------------------------------

  test 'requesting a link lands on the inbox screen, not a flash notice' do
    user = FactoryBot.create(:user)

    assert_enqueued_emails 1 do
      post auth_passwordless_path, params: { email: user.email }
    end
    assert_redirected_to auth_passwordless_inbox_path
    follow_redirect!

    assert_select 'h1.gh-h1', 'Sprawdź skrzynkę'
    assert_select 'p.gh-addr', user.email
    assert_select '.gh-big-ic i.fa-solid.fa-envelope'
    assert_select 'p.gh-small', /5 minut/
    assert_select 'a.gh-linkbtn', 'Zmień adres e-mail'
    # The address must not leak into any URL.
    assert_select 'a[href*=?]', user.email, false
  end

  test 'an unknown address reaches the identical screen (anti-enumeration)' do
    assert_nil User.find_by(email: 'nobody@example.com')

    assert_no_enqueued_emails do
      post auth_passwordless_path, params: { email: 'nobody@example.com' }
    end
    assert_redirected_to auth_passwordless_inbox_path
    follow_redirect!

    assert_select 'h1.gh-h1', 'Sprawdź skrzynkę'
    assert_select 'p.gh-addr', 'nobody@example.com'
    assert_select 'p.gh-small', /5 minut/
  end

  test 'the inbox screen redirects to the form when nothing is pending' do
    get auth_passwordless_inbox_path
    assert_redirected_to new_auth_passwordless_path
    assert_nil flash[:alert]
  end

  test 'the cooldown is anchored to the send, so a refresh resumes it' do
    user = FactoryBot.create(:user)
    post auth_passwordless_path, params: { email: user.email }

    travel 30.seconds do
      get auth_passwordless_inbox_path
      assert_select 'form[data-countdown-seconds-value=?]', '30'
      assert_select 'button.gh-btn[disabled]'
    end

    travel 61.seconds do
      get auth_passwordless_inbox_path
      assert_select 'form[data-countdown-seconds-value=?]', '0'
      assert_select 'button.gh-btn[disabled]', false
      assert_select 'button.gh-btn', 'Wyślij link ponownie'
    end
  end

  test 'a pending send older than the link lifetime falls back to the form' do
    user = FactoryBot.create(:user)
    post auth_passwordless_path, params: { email: user.email }

    travel 1.minute + LoginToken::EXPIRES_IN do
      get auth_passwordless_inbox_path
      assert_redirected_to new_auth_passwordless_path
    end
  end

  test 'resending re-arms the countdown and says the old link is dead' do
    user = FactoryBot.create(:user)
    post auth_passwordless_path, params: { email: user.email }

    travel 61.seconds do
      assert_enqueued_emails 1 do
        post auth_passwordless_path, params: { email: user.email }
      end
      assert_equal 'Wysłaliśmy nowy link. Poprzedni już nie działa.', flash[:notice]
      follow_redirect!
      assert_select 'form[data-countdown-seconds-value=?]', '60'
    end
  end

  test 'changing the address clears the pending send' do
    user = FactoryBot.create(:user)
    post auth_passwordless_path, params: { email: user.email }

    get new_auth_passwordless_path
    get auth_passwordless_inbox_path
    assert_redirected_to new_auth_passwordless_path
  end

  test 'a bypass account logs straight in and never sees the inbox' do
    user = FactoryBot.create(:user)
    BypassLoginService.any_instance.stubs(:can_bypass_login?).returns(true)

    assert_no_enqueued_emails do
      post auth_passwordless_path, params: { email: user.email }
    end

    assert_redirected_to home_path
    assert_nil session[:pending_login_email]
  end
end
