# frozen_string_literal: true

class SessionUserBuilder
  attr_reader :provider

  def initialize(provider)
    @provider = provider
  end

  def build
    user_params = @provider.user_params.merge(first_login: false)
    user = find_or_initialize_user

    if user.new_record?
      user.assign_attributes(user_params)
      user.save!(context: :account_setup)
    elsif user.first_login?
      user.update!(user_params, context: :account_setup)
    end

    user
  end

  private

  def find_or_initialize_user
    if @provider.usos_id
      User.find_or_initialize_by(
        usos_id:         @provider.usos_id,
        university_name: @provider.university_name,
      )
    elsif @provider.email
      User.find_or_initialize_by(email: @provider.email)
    else
      raise Providers::BaseAdapter::InvalidAuthError
    end
  end
end
