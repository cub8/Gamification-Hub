# frozen_string_literal: true

module OrganizationsHelper
  USER_ROLE_LABELS = {
    'student' => 'Student',
    'teacher' => 'Nauczyciel',
  }.freeze

  def user_role_label(role)
    USER_ROLE_LABELS.fetch(role.to_s, role.to_s.humanize)
  end

  def user_role_options
    User::INVITABLE_ROLES.map { |role| [user_role_label(role), role] }
  end
end
