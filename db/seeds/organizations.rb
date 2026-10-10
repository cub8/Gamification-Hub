# frozen_string_literal: true

module Seeds
  class Organizations < Base
    ORGANIZATIONS = [
      # Same name as the seeded users' university_name - all of them (except global admins) become its members.
      { name: 'Example university', max_members: 50 },
      { name: 'Politechnika Przykładowa', max_members: 20 },
      # Matches Providers::UsosAdapter#university_name, so new USOS sign-ups have an organization to join.
      { name: 'Uniwersytet im. Adama Mickiewicza', max_members: 1000 },
    ].freeze

    ADMINS = {
      'Example university' => [
        { email: 'pawel.wisniewski@example.com' },
        # Invited but not yet set up - logging in leads to the account setup form.
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
        assign_members(organization)
      end

      log_finish 'organizations'
    end

    private

    def assign_members(organization)
      User.where(university_name: organization.name, organization_id: nil)
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
