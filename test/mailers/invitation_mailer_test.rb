# frozen_string_literal: true

require 'test_helper'

class InvitationMailerTest < ActionMailer::TestCase
  test 'admin invitation_email' do
    mail = invitation_email(:admin)
    assert_equal 'Zaproszenie do systemu GamificationHub', mail.subject
    assert_equal ['jan.nowak@example.com'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'administrator organizacji Uniwersytet', mail.html_part.body.decoded
    assert_match 'http://example.com/test', mail.html_part.body.decoded
  end

  test 'invitation_email embeds its stylesheet' do
    html = invitation_email(:member).html_part.body.decoded

    assert_match(/<style>.*\.gh-invitation-email-button \{/m, html)
    assert_match 'class="gh-invitation-email-button"', html
  end

  test 'member invitation_email' do
    mail = invitation_email(:member)
    assert_match 'członek organizacji Uniwersytet', mail.html_part.body.decoded
    assert_match 'członek organizacji Uniwersytet', mail.text_part.body.decoded
  end

  private

  def invitation_email(role)
    InvitationMailer.with(
      token_link:        'http://example.com/test',
      email:             'jan.nowak@example.com',
      organization_name: 'Uniwersytet',
      role:              role,
    ).invitation_email
  end
end
