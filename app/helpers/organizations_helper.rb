# frozen_string_literal: true

module OrganizationsHelper
  USER_ROLE_LABELS = {
    'student' => 'Student',
    'teacher' => 'Nauczyciel',
  }.freeze

  def user_role_label(role)
    str_role = role.to_s
    USER_ROLE_LABELS.fetch(str_role, str_role.humanize)
  end

  def organization_capacity_lead(organization, members)
    free = [organization.max_members - members, 0].max
    free_text = gh_plural(free, 'wolne', 'wolne', 'wolnych')

    "#{members} z #{organization.max_members} miejsc zajętych · #{free} #{free_text}"
  end

  def user_role_options
    User::INVITABLE_ROLES.map { |role| [user_role_label(role), role] }
  end
end
