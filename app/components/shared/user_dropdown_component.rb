# frozen_string_literal: true

class Shared::UserDropdownComponent < ViewComponent::Base
  ROLES_MAP = {
    'student'            => 'Student',
    'teacher'            => 'Nauczyciel',
    'organization_admin' => 'Administrator organizacji',
    'global_admin'       => 'Administrator globalny',
  }.freeze

  attr_reader :user

  def initialize(user:)
    @user = user
  end

  private

  def user_title
    ROLES_MAP[@user.role]
  end
end
