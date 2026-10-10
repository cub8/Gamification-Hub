# frozen_string_literal: true

module HomeHelper
  def home_greeting(user)
    first_name = user.full_name.to_s.split.first

    first_name ? "Dzień dobry, #{first_name}" : 'Dzień dobry'
  end
end
