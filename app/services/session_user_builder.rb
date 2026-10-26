# frozen_string_literal: true

class SessionUserBuilder
  attr_reader :provider

  def initialize(provider)
    @provider = provider
  end

  def build
    @user_params = @provider.user_params
    user = find_or_initialize_user
    join_usos_organization(user)

    if user.new_record? || user.first_login?
      complete_setup(user)
    elsif user.organization_id_changed?
      user.save!
    end

    user
  end

  private

  def join_usos_organization(user)
    return if user.organization_admin? || user.global_admin?

    user.organization = Organization.usos
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
