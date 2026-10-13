# frozen_string_literal: true

require 'test_helper'

class OrganizationAdminMailerTest < ActionMailer::TestCase
  test 'invitation_email' do
    mail = OrganizationAdminMailer.with(
      token_link:        'http://example.com/test',
      email:             'jan.nowak@example.com',
      organization_name: 'Uniwersytet',
    ).invitation_email
    assert_equal 'Zaproszenie do systemu GamificationHub', mail.subject
    assert_equal ['jan.nowak@example.com'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'administrator organizacji Uniwersytet', mail.html_part.body.decoded
    assert_match 'http://example.com/test', mail.html_part.body.decoded
  end
end
