# frozen_string_literal: true

module OrganizationsHelper
  def user_role_label(role)
    str_role = role.to_s
    t("organizations.roles.#{str_role}", default: str_role.humanize)
  end

  def organization_capacity_lead(organization, members)
    if organization.unlimited?
      return t('organizations.helpers.capacity_unlimited',
               accounts: t('organizations.helpers.capacity_accounts', count: members),)
    end

    free = [organization.max_members - members, 0].max

    t('organizations.helpers.capacity_limited', members: members,
                                                max:     organization.max_members,
                                                free:    t('organizations.helpers.capacity_free', count: free),)
  end

  def user_role_options
    User::INVITABLE_ROLES.map { |role| [user_role_label(role), role] }
  end
end
