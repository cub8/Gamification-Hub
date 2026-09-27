# frozen_string_literal: true

class OrganizationsController < ApplicationController
  before_action :set_organization, only: %i[show edit update destroy new_admin add_admin]

  def index
    @organizations = policy_scope(Organization)
  end

  def show
    authorize @organization

    @admins = @organization.users.organization_admin
  end

  def new
    @organization = Organization.new
    authorize @organization
  end

  def create
    @organization = Organization.new(organization_params)

    authorize @organization

    if @organization.save
      redirect_outside_turbo_frame organization_path(@organization),
                                   notice: 'Pomyślnie utworzono organizację.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @organization
  end

  def update
    if @organization.update(organization_params)
      redirect_outside_turbo_frame organization_path(@organization),
                                   notice: 'Pomyślnie zaktualizowano organizację.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @organization

    @organization.destroy!
    redirect_to organizations_path, notice: 'Pomyślnie usunięto organizację.', status: :see_other
  end

  def new_admin
    @org_admin = User.new
  end

  def add_admin
    @org_admin = User.new(user_params)
    @org_admin.organization = @organization
    @org_admin.university_name = @organization.name
    @org_admin.role = 3

    if @org_admin.save
      redirect_outside_turbo_frame organization_path(@organizaton),
                                   notice: 'Pomyślnie dodano administratora organizacji.'
    else
      render :new_admin, status: :unprocessable_content
    end
  end

  def set_organization
    @organization = Organization.find(params.expect(:id))
  end

  def organization_params
    params.expect(
      organization: %i[
        name
        max_members
      ],
    )
  end

  def user_params
    params.expect(
      user: %i[
        email
        full_name
      ],
    )
  end
end
