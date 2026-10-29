# frozen_string_literal: true

class Organizations::AdminsController < ApplicationController
  before_action :set_presentation
  before_action :set_organization
  before_action :set_admin

  def confirm_destroy; end

  def destroy
    @admin.destroy!

    redirect_after_destroy notice: t('organizations.flash.admin_removed', name: display_name)
  end

  private

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  def set_organization
    @organization = Organization.find(params.expect(:organization_id))
    authorize @organization, :manage_admins?
  end

  def set_admin
    @admin = @organization.users.organization_admin.find(params.expect(:id))
  end

  def display_name
    @admin.full_name.presence || @admin.email
  end

  def redirect_after_destroy(notice:)
    path = organization_path(@organization)
    return redirect_outside_turbo_frame(path, notice: notice) if @in_modal

    redirect_to path, notice: notice, status: :see_other
  end
end
