# frozen_string_literal: true

class SessionUserBuilder
  class OrganizationNotFoundError < StandardError; end
  class OrganizationFullError < StandardError; end

  attr_reader :provider

  def initialize(provider)
    @provider = provider
  end

  def build
    # Also populates the provider's attributes (email, usos_id, university_name) used below.
    @user_params = @provider.user_params
    user = find_or_initialize_user

    if user.new_record?
      create_in_organization(user)
    elsif user.first_login?
      complete_setup(user)
    end

    user
  end

  private

  # New accounts join the organization named after the provider's university.
  # The lock keeps concurrent sign-ups from overfilling it.
  def create_in_organization(user)
    organization = Organization.find_by(name: @provider.university_name)
    raise OrganizationNotFoundError unless organization

    organization.with_lock do
      raise OrganizationFullError if organization.full?

      user.organization = organization
      complete_setup(user)
    end
  end

  def complete_setup(user)
    user.assign_attributes(@user_params)
    user.first_login = false
    user.save!(context: :account_setup)
  end

  def find_or_initialize_user
    if @provider.usos_id
      user = User.find_by(
        usos_id:         @provider.usos_id,
        university_name: @provider.university_name,
      )
      return user if user
    end

    if @provider.email
      User.find_or_initialize_by(email: @provider.email)
    elsif @provider.usos_id
      User.find_or_initialize_by(
        usos_id:         @provider.usos_id,
        university_name: @provider.university_name,
      )
    else
      raise Providers::InvalidAuthError
    end
  end
end
