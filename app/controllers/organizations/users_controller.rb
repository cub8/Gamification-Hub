# frozen_string_literal: true

class Organizations::UsersController < ApplicationController
  helper OrganizationsHelper

  before_action :set_presentation
  before_action :set_organization
  before_action :set_user

  def edit; end

  def update
    @user.assign_attributes(user_params)

    if @user.save(context: :user_invitation)
      redirect_after_save notice: "Zapisano zmiany: #{@user.full_name}."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def confirm_destroy; end

  def destroy
    name = @user.full_name
    @user.destroy!

    redirect_after_save notice: "Usunięto użytkownika: #{name}."
  end

  private

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  def redirect_after_save(notice:)
    path = organization_path(@organization)
    return redirect_outside_turbo_frame(path, notice: notice) if @in_modal

    redirect_to path, notice: notice, status: :see_other
  end

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
