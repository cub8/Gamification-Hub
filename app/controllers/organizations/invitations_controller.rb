# frozen_string_literal: true

class Organizations::InvitationsController < ApplicationController
  include InvitationDelivery

  rate_limit to: 3, within: 10.minutes, by: -> { params[:user_id] }, with: -> { too_many_resends }, only: :create

  def create
    organization = Organization.find(params.expect(:organization_id))
    user = organization.users.where(first_login: true).find(params.expect(:user_id))
    authorize organization, user.organization_admin? ? :add_admin? : :add_user?

    send_invitation(user, create_invitation_token(user))

    redirect_to organization_path(organization), status: :see_other,
                                                 notice: "Wysłano ponownie zaproszenie: #{user.email}."
  end

  private

  def too_many_resends
    redirect_to organization_path(params[:organization_id]),
                alert:  'Zaproszenie zostało już wysłane kilka razy. Spróbuj ponownie za kilka minut.',
                status: :see_other
  end
end
