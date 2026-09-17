# frozen_string_literal: true

module Redesign
  # A group's front page, as its teacher reads it. Mockup: #/t/home, vHome(),
  # js-expanded/30-gh.js:33-44.
  #
  # The mockup answers three questions on this screen — how is the group doing,
  # what has just happened, what needs me — and each is a query, so this is a
  # service, like Shop and StudentList. Everything is resolved once here so the
  # view can stay a rendering of it.
  #
  # Replaces StoryGroupTeacherDashboard, and fixes two things it got wrong:
  # "recent" sheets were ordered oldest-first, and the per-sheet podium summed
  # rewards across every student holding those categories before filtering the
  # result in Ruby.
  class TeacherOverview
    include Rails.application.routes.url_helpers

    # The KPI strip's window. A week, because a teaching group's rhythm is
    # weekly — "since yesterday" is the Start screen's window, not a group's.
    WINDOW = 7.days

    # How many sheets carry a podium, and how many rows "Wymaga uwagi" holds
    # before it stops being a list and starts being a backlog.
    SHEETS = 2
    ATTENTION = 4

    Kpi      = Struct.new(:label, :value, :note)
    Purchase = Struct.new(:transaction, :student, :item) do
      def price        = transaction.amount.abs
      def time         = transaction.created_at
      def student_name = student.display_name
    end
    Sheet    = Struct.new(:activity_group, :podium)
    Place    = Struct.new(:student, :points)

    def initialize(story_group:)
      @story_group = story_group
    end

    attr_reader :story_group, :kpis, :purchases, :attention, :recent_sheets

    def load
      @kpis          = build_kpis
      @purchases     = build_purchases
      @attention     = build_attention
      @recent_sheets = build_recent_sheets
      self
    end

    def owner = story_group.owner

    def students_count = @students_count ||= memberships.size

    private

    # ---- KPIs --------------------------------------------------------------

    def build_kpis
      spent = purchase_scope.sum(:amount).abs
      bought = purchase_scope.count
      earned = window_scope.reward.sum(:amount)

      [
        Kpi.new(label: 'Studenci', value: students_count),
        Kpi.new(label: 'Zakupy w tym tygodniu', value: bought, note: (spent.positive? ? "za #{spent}" : nil)),
        Kpi.new(label: 'Nagrody w tym tygodniu', value: earned),
        Kpi.new(label: 'Ranking', value: story_group.ranking_summary),
      ]
    end

    def window_scope
      CurrencyTransaction.where(student_id: membership_ids)
                         .where(created_at: WINDOW.ago..)
    end

    def purchase_scope = @purchase_scope ||= window_scope.purchase

    # ---- Recent purchases --------------------------------------------------

    def build_purchases
      CurrencyTransaction.purchase
                         .where(student_id: membership_ids)
                         .includes(:transactionable, student: :user)
                         .order(created_at: :desc)
                         .limit(8)
                         .map do |transaction|
        # Nil when the item was hard-deleted — soft delete keeps it, but rows
        # predating that migration still exist, so the row renders without art
        # rather than raising.
        Purchase.new(transaction: transaction, student: transaction.student,
                     item: transaction.transactionable,)
      end
    end

    # ---- Wymaga uwagi ------------------------------------------------------

    # Read in severity order: somebody blocked out of the shop, then the
    # teacher's own unfinished work.
    #
    # Deliberately NOT "n do awansu". A student climbing toward a rung is the
    # system working; a panel that reports it stops being a list of things that
    # need doing and becomes a feed.
    def build_attention
      (out_of_lives + [ungraded_sheet]).compact.first(ATTENTION)
    end

    def out_of_lives
      memberships.select { |membership| membership.lives.to_i.zero? }
                 .map do |membership|
        AttentionItem.new(
          icon: 'fa-heart', tone: 'zero',
          title: "#{membership.display_name} ma 0 żyć",
          detail: 'Kupi tylko przedmioty dostępne przy 0 życiach.',
          action_label: 'Otwórz',
          action_path: story_group_student_path(story_group, membership),
        )
      end
    end

    # The newest sheet that still has a column nobody has been awarded in.
    #
    # There is no "finished" flag in the schema, so pending has to be defined
    # rather than read, and this is TeacherStartDashboard#build_pending's
    # definition scoped to one group: a column with zero awards. It is the
    # cheapest one that never calls a fully-awarded sheet pending just because
    # one student legitimately missed a column.
    def ungraded_sheet
      activity_group = story_group.activity_groups
                                  .where(id: ungraded_category_scope.select(:activity_group_id))
                                  .order(created_at: :desc)
                                  .first
      return if activity_group.nil?

      pending = ungraded_category_scope.where(activity_group_id: activity_group.id).count
      awarded = StudentsActivityGroupCategory
                .where(activity_group_category_id: activity_group.activity_group_category_ids).count

      AttentionItem.new(
        icon: 'fa-table', emphasis: true,
        title: "#{activity_group.name} w trakcie",
        detail: "Przyznano #{awarded} #{Plural.pick(awarded, 'nagrodę', 'nagrody', 'nagród')}, " \
                "#{pending} #{Plural.pick(pending, 'kolumna', 'kolumny', 'kolumn')} bez ocen.",
        action_label: 'Oceń',
        action_path: edit_story_group_activity_group_students_activity_group_categories_path(story_group,
                                                                                             activity_group,),
      )
    end

    def ungraded_category_scope
      ActivityGroupCategory.where(activity_group_id: story_group.activity_groups.select(:id))
                           .where.missing(:students_activity_group_categories)
    end

    # ---- Ostatnie arkusze --------------------------------------------------

    def build_recent_sheets
      sheets = story_group.activity_groups.order(created_at: :desc).limit(SHEETS).to_a
      return [] if sheets.empty?

      category_ids = ActivityGroupCategory.where(activity_group_id: sheets.map(&:id))
                                          .pluck(:activity_group_id, :id)
                                          .group_by(&:first)
                                          .transform_values { |pairs| pairs.map(&:last) }

      sheets.map do |sheet|
        Sheet.new(activity_group: sheet, podium: podium_for(category_ids[sheet.id]))
      end
    end

    # One grouped sum per sheet, scoped to THIS group's students in SQL: summing
    # every holder of those categories and discarding the strangers afterwards
    # both over-counts nothing and reads more rows than it has to.
    def podium_for(category_ids)
      return [] if category_ids.blank?

      totals = StudentsActivityGroupCategory
               .joins(:activity_group_category)
               .where(activity_group_category_id: category_ids, student_id: membership_ids)
               .group(:student_id)
               .sum('activity_group_categories.reward')

      totals.sort_by { |_, points| -points }
            .first(3)
            .filter_map do |student_id, points|
              (student = memberships_by_id[student_id]) && Place.new(student: student, points: points)
            end
    end

    # ---- Shared loads ------------------------------------------------------

    def memberships = @memberships ||= story_group.student_memberships.with_user.to_a

    def memberships_by_id = @memberships_by_id ||= memberships.index_by(&:id)

    def membership_ids = @membership_ids ||= memberships.map(&:id)
  end
end
