# frozen_string_literal: true

# Start screen for a global admin: every organization with its fill level, and
# the ones that need a hand - no admin yet, or (nearly) out of seats.
class GlobalAdminStartDashboard
  NEARLY_FULL = 0.9

  Org = Data.define(:organization, :member_count, :admins, :pending_admins) do
    def free = [organization.max_members - member_count, 0].max
    def fill_percent = (member_count * 100.0 / organization.max_members).clamp(0, 100).round
    def full? = member_count >= organization.max_members
    def nearly_full? = member_count >= organization.max_members * NEARLY_FULL
    def no_admin? = admins.zero?
  end

  Tile = Data.define(:label, :value, :note)

  attr_reader :organizations

  def load
    @organizations = build_organizations
    self
  end

  def stat_tiles
    [
      Tile.new(label: 'Organizacje', value: organizations.size, note: nil),
      Tile.new(label: 'Konta w organizacjach', value: organizations.sum(&:member_count), note: nil),
      Tile.new(label: 'Wolne miejsca', value: organizations.sum(&:free), note: nil),
      Tile.new(label: 'Niezaakceptowane zaproszenia', value: organizations.sum(&:pending_admins), note: nil),
    ]
  end

  def without_admin = organizations.select(&:no_admin?)
  def nearly_full = organizations.select(&:nearly_full?)
  def attention? = without_admin.any? || nearly_full.any?

  private

  def build_organizations
    organizations = Organization.order(:name).to_a
    users   = User.where(organization: organizations).group(:organization_id)
    members = users.count
    admins  = users.organization_admin.count
    pending = users.organization_admin.where(first_login: true).count

    organizations.map do |organization|
      Org.new(
        organization:   organization,
        member_count:   members.fetch(organization.id, 0),
        admins:         admins.fetch(organization.id, 0),
        pending_admins: pending.fetch(organization.id, 0),
      )
    end
  end
end
