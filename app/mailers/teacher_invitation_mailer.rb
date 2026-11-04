# frozen_string_literal: true

class TeacherInvitationMailer < ApplicationMailer
  def invitation_email
    assign_common
    mail to: @email, subject: t('.subject', group: @group_name)
  end

  def added_email
    assign_common
    mail to: @email, subject: t('.subject', group: @group_name)
  end

  private

  def assign_common
    @email = params[:email]
    @link = params[:link]
    @group_name = params[:group_name]
    @inviter_name = params[:inviter_name]
  end
end
