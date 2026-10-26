# frozen_string_literal: true

module Seeds
  class Organizations < Base
    ORGANIZATIONS = [
      { name: 'Example university', max_members: 50 },
      { name: 'Politechnika Przykładowa', max_members: 20 },
    ].freeze

    # University name the USOS adapter stamps on accounts.
    USOS_UNIVERSITY_NAME = 'Uniwersytet im. Adama Mickiewicza'

    ADMINS = {
      'Example university' => [
        { email: 'pawel.wisniewski@example.com' },
        { email: 'zofia.nowicka@example.com', full_name: nil, first_login: true },
      ],
    }.freeze

    def call
      log_start 'organizations'

      ORGANIZATIONS.each do |organization_data|
        organization = Organization.find_or_create_by!(name: organization_data[:name]) do |org|
          org.max_members = organization_data[:max_members]
        end

        build_admins(organization)
        assign_members(organization, university_name: organization.name)
      end

      assign_members(Organization.usos, university_name: USOS_UNIVERSITY_NAME)

      log_finish 'organizations'
    end

    private

    def assign_members(organization, university_name:)
      User.where(university_name: university_name, organization_id: nil)
          .where.not(role: :global_admin)
          .find_each { |user| user.update!(organization: organization) }
    end

    def build_admins(organization)
      ADMINS.fetch(organization.name, []).each do |admin_data|
        admin = User.find_by(email: admin_data[:email]) ||
                FactoryBot.build(:user, :organization_admin, **admin_data, usos_id: nil, university_number: nil)

        admin.update!(organization: organization, university_name: organization.name)
      end
    end
  end
end
