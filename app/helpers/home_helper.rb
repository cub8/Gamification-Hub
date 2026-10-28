# frozen_string_literal: true

module HomeHelper
  def home_greeting(user)
    first_name = user.full_name.to_s.split.first
    base_greeting = 'Dzień dobry'
    return base_greeting if first_name.blank?

    "#{base_greeting}, #{first_name}"
  end
end
