# frozen_string_literal: true

# The teacher landing screen (mockup `#/t/dash`).
#
# The cross-group counterpart to StoryGroupTeacherDashboard, which is scoped to
# a single group: recent purchases across every group the teacher owns or
# supports, the groups themselves, and the sheet most in need of grading.
class TeacherStartDashboard
  PURCHASE_LIMIT = 30

  # Buckets in render order. "Recent" — what the greeting counts and what the
  # per-group "nowe zakupy" badge counts — is today plus yesterday.
  DAYS = %w[Dziś Wczoraj Wcześniej].freeze
  RECENT_DAYS = DAYS.first(2).freeze

  Purchase = Data.define(:transaction, :student, :story_group, :item, :day) do
    def price = transaction.amount.abs
    def time = transaction.created_at.strftime('%H:%M')
    def student_name = student.full_name
  end

  Group = Data.define(:story_group, :role, :students_count, :new_purchases)

  Pending = Data.define(:activity_group, :story_group, :categories_count, :students_count)

  attr_reader :purchases, :groups, :pending, :filter

  # `filter` is a story group id, or nil for "all groups". Filtering is
  # server-side (a link, not a click handler) so the choice survives a refresh.
  def initialize(user:, filter: nil)
    @user = user
    @filter = filter.presence&.to_i
  end

  def load
    @groups    = build_groups
    @purchases = build_purchases
    @pending   = build_pending
    self
  end

  # The greeting counts only the recent window, across all groups — it
  # describes the teacher's world, not the current filter.
  def recent_purchases
    @recent_purchases ||= all_purchases.select { |purchase| RECENT_DAYS.include?(purchase.day) }
  end

  def recent_group_count
    recent_purchases.map { |purchase| purchase.story_group.id }
                    .uniq.count
  end

  # Rows for one day bucket, honouring the filter.
  def purchases_on(day)
    purchases.select { |purchase| purchase.day == day }
  end

  private

  def story_groups
    @story_groups ||= @user.all_story_groups.select { |group| group.owner_id == @user.id || teaches?(group) }
  end

  def teaches?(story_group)
    teacher_group_ids.include?(story_group.id)
  end

  def teacher_group_ids
    @teacher_group_ids ||= @user.teacher_story_groups.ids
  end

  def story_group_ids
    @story_group_ids ||= story_groups.map(&:id)
  end

  def build_groups
    counts = StoryGroupStudent.where(story_group_id: story_group_ids).group(:story_group_id).count
    fresh  = recent_purchases.group_by { |purchase| purchase.story_group.id }

    summaries = story_groups.map do |story_group|
      Group.new(
        story_group:    story_group,
        role:           story_group.owner_id == @user.id ? 'Prowadzisz' : 'Wspierasz',
        students_count: counts.fetch(story_group.id, 0),
        new_purchases:  fresh.fetch(story_group.id, []).size,
      )
    end

    summaries.sort_by { |group| group.story_group.name.to_s.downcase }
  end

  def build_purchases
    return all_purchases if filter.nil?

    all_purchases.select { |purchase| purchase.story_group.id == filter }
  end

  def all_purchases
    @all_purchases ||= begin
      groups_by_id = story_groups.index_by(&:id)

      CurrencyTransaction
        .purchase
        .where(student_id: StoryGroupStudent.where(story_group_id: story_group_ids).select(:id))
        .includes(:transactionable, student: :user)
        .order(created_at: :desc)
        .limit(PURCHASE_LIMIT)
        .map do |transaction|
          Purchase.new(
            transaction: transaction,
            student:     transaction.student,
            story_group: groups_by_id[transaction.student.story_group_id],
            # Nil when the item was hard-deleted. Soft delete (D1) will make
            # this always present; until then the row renders without art
            # rather than raising.
            item:        transaction.transactionable,
            day:         bucket_for(transaction.created_at),
          )
        end
    end
  end

  def bucket_for(time)
    case time.to_date
    when Date.current      then DAYS[0]
    when Date.yesterday    then DAYS[1]
    else                        DAYS[2]
    end
  end

  # The sheet most worth opening: the newest one that still has a category
  # nobody has been awarded in.
  #
  # There is no "sheet finished" flag in the schema, so "pending" has to be
  # defined rather than read. A category with zero awards is the cheapest
  # definition that never cries wolf — it cannot call a fully-awarded sheet
  # pending just because one student legitimately missed one category.
  def build_pending
    return if story_group_ids.empty?

    activity_group = ActivityGroup
                     .where(story_group_id: story_group_ids)
                     .where(id: ActivityGroupCategory.where.missing(:students_activity_group_categories)
                                                     .select(:activity_group_id))
                     .order(created_at: :desc)
                     .first
    return unless activity_group

    pending_count = ActivityGroupCategory
                    .where(activity_group_id: activity_group.id)
                    .where.missing(:students_activity_group_categories)
                    .count

    Pending.new(
      activity_group:   activity_group,
      story_group:      story_groups.find { |group| group.id == activity_group.story_group_id },
      categories_count: pending_count,
      students_count:   StoryGroupStudent.where(story_group_id: activity_group.story_group_id).count,
    )
  end
end
