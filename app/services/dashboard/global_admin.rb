# frozen_string_literal: true

class Dashboard::GlobalAdmin
  NEARLY_FULL = 0.9

  Org = Data.define(:organization, :member_count, :admins, :pending_admins) do
    include Dashboard::Capacity

    def max_members = organization.max_members
    def nearly_full? = !unlimited? && member_count >= max_members * NEARLY_FULL
    def no_admin? = admins.zero?
  end

  attr_reader :organizations

  def load
    @organizations = build_organizations
    self
  end

  def to_partial_path = 'home/global_admin_start'

  def stat_tiles
    [
      Dashboard::Tile.new(label: 'Organizacje', value: organizations.size, note: nil),
      Dashboard::Tile.new(label: 'Konta w organizacjach', value: organizations.sum(&:member_count), note: nil),
      Dashboard::Tile.new(label: 'Wolne miejsca', value: organizations.sum { |org| org.free.to_i }, note: nil),
      Dashboard::Tile.new(label: 'Niezaakceptowane zaproszenia', value: organizations.sum(&:pending_admins), note: nil),
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
