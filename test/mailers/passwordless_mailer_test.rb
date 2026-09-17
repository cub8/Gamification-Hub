# frozen_string_literal: true

require 'test_helper'

class PasswordlessMailerTest < ActionMailer::TestCase
  test 'token_email' do
    mail = PasswordlessMailer.with(
      token_link: 'http://example.com/test',
      email:      'jan.nowak@example.com',
      user_name:  'Jan Nowak',
    ).token_email
    assert_equal 'Logowanie do systemu Gamification Hub', mail.subject
    assert_equal ['jan.nowak@example.com'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'Cześć, Jan!', mail.html_part.body.decoded
    assert_match 'http://example.com/test', mail.html_part.body.decoded
    assert_match 'Cześć, Jan!', mail.text_part.body.decoded
    assert_match 'http://example.com/test', mail.text_part.body.decoded
  end
end
