# frozen_string_literal: true

module Auth::SignIn
  extend ActiveSupport::Concern

  private

  def sign_in_and_redirect(user)
    return_to = session[:return_to]
    joined = TeacherInvitationAcceptor.new(user).call
    reset_session
    session[:user_id] = user.id

    redirect_to after_login_path(return_to, joined), notice: sign_in_notice(joined)
  end

  def after_login_path(path, joined = [])
    return path if local_path?(path)
    return story_group_path(joined.first) if joined.any?

    home_path
  end

  def sign_in_notice(joined)
    return t('auth.flash.signed_in') if joined.empty?

    t('auth.flash.joined_as_teacher', groups: joined.map(&:name).to_sentence)
  end

  def local_path?(path)
    path&.start_with?('/') && !path.start_with?('//')
  end
end
