# frozen_string_literal: true

class OrganizationsController < ApplicationController
  ADMIN_INVITATION_EXPIRES_IN = 7.days
  USER_INVITATION_EXPIRES_IN = 7.days

  before_action :set_organization, only: %i[show edit update destroy new_admin add_admin new_user add_user]

  def index
    @organizations = policy_scope(Organization)
  end

  def show
    authorize @organization

    @admins = @organization.users.organization_admin

    return unless @current_user.organization_admin?

    @users = @organization.users.where(role: User::INVITABLE_ROLES).order(:created_at)
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
    authorize @organization

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
    authorize @organization

    @org_admin = User.new
  end

  def add_admin
    authorize @organization

    @org_admin = User.new(user_params)
    @org_admin.organization = @organization
    @org_admin.university_name = @organization.name
    @org_admin.role = :organization_admin
    @org_admin.first_login = true

    token = User.transaction do
      @org_admin.save(context: :admin_invitation) &&
        @org_admin.create_login_token!(expires_in: ADMIN_INVITATION_EXPIRES_IN)
    end

    if token
      send_admin_invitation(token)
      redirect_outside_turbo_frame organization_path(@organization),
                                   notice: 'Pomyślnie dodano administratora organizacji. Wysłano zaproszenie na email.'
    else
      render :new_admin, status: :unprocessable_content
    end
  end

  def new_user
    authorize @organization

    @new_user = User.new
  end

  def add_user
    authorize @organization

    @new_user = User.new(user_params)
    @new_user.organization = @organization
    @new_user.university_name = @organization.name
    @new_user.first_login = true

    token = User.transaction do
      @new_user.save(context: :user_invitation) &&
        @new_user.create_login_token!(expires_in: USER_INVITATION_EXPIRES_IN)
    end

    if token
      send_user_invitation(token)
      redirect_outside_turbo_frame organization_path(@organization),
                                   notice: 'Pomyślnie dodano użytkownika do organizacji. Wysłano zaproszenie na email.'
    else
      render :new_user, status: :unprocessable_content
    end
  end

  private

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

  def send_admin_invitation(token)
    OrganizationAdminMailer.with(
      token_link:        auth_passwordless_verify_url(token: token.raw_token),
      email:             @org_admin.email,
      organization_name: @organization.name,
    ).invitation_email.deliver_later
  end

  def send_user_invitation(token)
    NewUserMailer.with(
      token_link:        auth_passwordless_verify_url(token: token.raw_token),
      email:             @new_user.email,
      organization_name: @organization.name,
    ).invitation_email.deliver_later
  end

  def admin_params
    params.expect(
      user: %i[
        email
      ],
    )
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
