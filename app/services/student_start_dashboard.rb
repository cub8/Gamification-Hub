# frozen_string_literal: true

# The student landing screen (mockup `#/s/start`).
#
# The cross-group counterpart to StudentOverview, which is scoped to
# a single group. Currency, ranks and badges are separate in every group, so
# this loads one summary per membership rather than one total.
class StudentStartDashboard
  # How many rows the "Ostatnio we wszystkich grupach" feed shows.
  FEED_LIMIT = 8

  Group = Data.define(
    :membership, :story_group, :rank, :next_rank, :badges_earned, :badges_total,
  ) do
    def balance = membership.current_currency.to_i
    def total = membership.total_currency.to_i
    def lives = membership.lives.to_i

    # A group you have joined but never earned in. The mockup calls this
    # `fresh` and shows an explanation instead of a meaningless zero.
    def fresh? = total.zero?

    # Progress toward the next rank. Full when there is no next rank, so a
    # maxed-out student sees a complete bar rather than an empty one.
    def next_threshold = next_rank&.required_currency_value.to_i
  end

  attr_reader :groups, :feed

  def initialize(user:)
    @user = user
  end

  def load
    @groups = build_groups
    @feed   = load_feed
    self
  end

  private

  def memberships
    @memberships ||= @user.student_memberships
                          .includes(story_group: { icon_attachment: :blob, currency_icon_attachment: :blob })
                          .to_a
  end

  def build_groups
    badge_totals = Badge.kept.where(story_group_id: memberships.map(&:story_group_id))
                        .group(:story_group_id)
                        .count
    earned = StudentsBadge.where(story_group_student_id: memberships.map(&:id))
                          .group(:story_group_student_id)
                          .count

    summaries = memberships.map do |membership|
      Group.new(
        membership:    membership,
        story_group:   membership.story_group,
        rank:          membership.rank,
        next_rank:     membership.next_rank,
        badges_earned: earned.fetch(membership.id, 0),
        badges_total:  badge_totals.fetch(membership.story_group_id, 0),
      )
    end

    summaries.sort_by { |group| group.story_group.name.to_s.downcase }
  end

  # Every currency movement across every group the student belongs to. The
  # mockup's feed is hard-coded sample copy, so the shape here is ours: the
  # same ledger rows the per-group history screen shows, merged and re-sorted.
  def load_feed
    CurrencyTransaction.where(student_id: memberships.map(&:id))
                       .includes(:transactionable, student: :story_group)
                       .order(created_at: :desc)
                       .limit(FEED_LIMIT)
  end
end
