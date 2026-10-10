# frozen_string_literal: true

class Organizations::UsersController < ApplicationController
  helper OrganizationsHelper

  before_action :set_organization
  before_action :set_user

  def edit; end

  def update
    @user.assign_attributes(user_params)

    if @user.save(context: :user_invitation)
      redirect_outside_turbo_frame organization_path(@organization),
                                   notice: 'Pomyślnie zaktualizowano użytkownika.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @user.destroy!
    redirect_to organization_path(@organization), notice: 'Pomyślnie usunięto użytkownika.', status: :see_other
  end

  private

  def set_organization
    @organization = Organization.find(params.expect(:organization_id))
    authorize @organization, :manage_users?
  end

  # Admins are managed separately, so only students and teachers are reachable here.
  def set_user
    @user = @organization.users.where(role: User::INVITABLE_ROLES).find(params.expect(:id))
  end

  def user_params
    params.expect(
      user: %i[
        email
        full_name
        university_number
        usos_id
        role
      ],
    )
  end
end
