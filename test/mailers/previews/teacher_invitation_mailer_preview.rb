# frozen_string_literal: true

class TeacherInvitationMailerPreview < ActionMailer::Preview
  def invitation_email
    mailer.invitation_email
  end

  def added_email
    mailer.added_email
  end

  private

  def mailer
    TeacherInvitationMailer.with(email:        'jan.nowak@example.com',
                                 link:         'http://example.com/test',
                                 group_name:   'Fizyka 1',
                                 inviter_name: 'Anna Kowalska',)
  end
end
