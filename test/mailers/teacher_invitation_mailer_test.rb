# frozen_string_literal: true

require 'test_helper'

class TeacherInvitationMailerTest < ActionMailer::TestCase
  test 'invitation_email carries the link and the group' do
    mail = mailer.invitation_email

    assert_equal 'Zaproszenie do prowadzenia grupy Fizyka 1', mail.subject
    assert_equal ['new@example.com'], mail.to
    assert_match 'Anna Kowalska zaprasza Cię do prowadzenia grupy Fizyka 1', mail.html_part.body.decoded
    assert_match 'Przyjmij zaproszenie', mail.html_part.body.decoded
    assert_match 'http://example.com/accept', mail.text_part.body.decoded
  end

  test 'added_email tells an existing teacher where the group is' do
    mail = mailer.added_email

    assert_equal 'Dodano Cię do grupy Fizyka 1', mail.subject
    assert_match 'Otwórz grupę', mail.html_part.body.decoded
    assert_no_match 'ważny przez 7 dni', mail.text_part.body.decoded
  end

  private

  def mailer
    TeacherInvitationMailer.with(email:        'new@example.com',
                                 link:         'http://example.com/accept',
                                 group_name:   'Fizyka 1',
                                 inviter_name: 'Anna Kowalska',)
  end
end
