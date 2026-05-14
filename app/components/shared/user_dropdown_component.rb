# frozen_string_literal: true

class Shared::UserDropdownComponent < ViewComponent::Base
  attr_reader :user

  def initialize(user:)
    @user = user
  end
end
