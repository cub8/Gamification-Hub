# frozen_string_literal: true

module HomeHelper
  def home_greeting(user)
    first_name = user.full_name.to_s.split.first

    return t('home.admin_greeting_anonymous') if first_name.blank?

    t('home.admin_greeting', name: first_name)
  end
end
