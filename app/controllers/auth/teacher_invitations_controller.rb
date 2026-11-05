# frozen_string_literal: true

class Auth::TeacherInvitationsController < ApplicationController
  include Auth::SignIn

  skip_before_action :authenticate!

  def show
    invitation = TeacherInvitation.find_by_accept_token(params.expect(:token))
    return redirect_to login_path, alert: t('auth.flash.invalid_invitation') if invitation.nil?

    user = User.find_by(email: invitation.email) || invitation.create_invitee!
    session[:return_to] = story_group_path(invitation.story_group)

    sign_in_and_redirect(user)
  rescue ActiveRecord::RecordInvalid
    redirect_to login_path, alert: t('auth.flash.invitation_failed')
  end
end
