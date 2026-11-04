# frozen_string_literal: true

module TeacherInvitationDelivery
  private

  def deliver_teacher_invitation(result)
    if result.status == :added
      teacher_invitation_mail(result.email, story_group_url(@story_group)).added_email.deliver_later
    else
      link = auth_teacher_invitation_url(token: result.invitation.accept_token)
      teacher_invitation_mail(result.email, link).invitation_email.deliver_later
    end
  end

  def teacher_invitation_mail(email, link)
    TeacherInvitationMailer.with(email:        email,
                                 link:         link,
                                 group_name:   @story_group.name,
                                 inviter_name: @current_user.full_name,)
  end
end
