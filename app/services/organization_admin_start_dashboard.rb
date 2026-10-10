# frozen_string_literal: true

# Start screen for an organization admin: who is in their organization, how
# many seats are left, and which invitations nobody has accepted yet.
class OrganizationAdminStartDashboard
  RECENT_LIMIT = 6

  Tile = GlobalAdminStartDashboard::Tile

  attr_reader :organization, :members, :recent_users, :pending_users

  def initialize(user:)
    @organization = user.organization
  end

  def load
    return self unless organization

    @members       = organization.users.count
    @counts        = organization.users.group(:role).count
    @recent_users  = invitable.order(created_at: :desc).limit(RECENT_LIMIT).to_a
    @pending_users = invitable.where(first_login: true).order(:created_at).to_a
    self
  end

  def free = [organization.max_members - members, 0].max
  def fill_percent = (members * 100.0 / organization.max_members).clamp(0, 100).round
  def full? = members >= organization.max_members

  def stat_tiles
    [
      Tile.new(label: 'Studenci', value: @counts.fetch('student', 0), note: nil),
      Tile.new(label: 'Nauczyciele', value: @counts.fetch('teacher', 0), note: nil),
      Tile.new(label: 'Wolne miejsca', value: free, note: "z #{organization.max_members}"),
      Tile.new(label: 'Oczekujące zaproszenia', value: pending_users.size, note: nil),
    ]
  end

  private

  def invitable
    organization.users.where(role: User::INVITABLE_ROLES)
  end
end
