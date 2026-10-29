# frozen_string_literal: true

class Dashboard::OrganizationAdmin
  include Dashboard::Capacity

  RECENT_LIMIT = 6

  attr_reader :organization, :member_count, :recent_users, :pending_users

  delegate :max_members, to: :organization

  def initialize(user:)
    @organization = user.organization
  end

  def load
    return self unless organization

    @member_count  = organization.users.count
    @counts        = organization.users.group(:role).count
    @recent_users  = invitable.order(created_at: :desc).limit(RECENT_LIMIT).to_a
    @pending_users = invitable.where(first_login: true).order(:created_at).to_a
    self
  end

  def to_partial_path = 'home/organization_admin_start'

  def stat_tiles
    [
      Dashboard::Tile.new(label: tile_text(:students), value: @counts.fetch('student', 0), note: nil),
      Dashboard::Tile.new(label: tile_text(:teachers), value: @counts.fetch('teacher', 0), note: nil),
      free_tile,
      Dashboard::Tile.new(label: tile_text(:pending), value: pending_users.size, note: nil),
    ]
  end

  private

  def free_tile
    return Dashboard::Tile.new(label: tile_text(:free), value: tile_text(:no_limit), note: nil) if unlimited?

    Dashboard::Tile.new(label: tile_text(:free), value: free,
                        note:  tile_text(:of_max, max: organization.max_members),)
  end

  def tile_text(key, **)
    I18n.t("home.organization_admin_start.tiles.#{key}", **)
  end

  def invitable
    organization.users.where(role: User::INVITABLE_ROLES)
  end
end
