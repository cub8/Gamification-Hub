# frozen_string_literal: true

class StoryGroupTeacherDashboard
  attr_reader :recent_transactions, :recent_activity_groups, :activity_group_rankings

  def initialize(story_group:)
    @story_group = story_group
  end

  def load
    @recent_transactions     = load_recent_transactions
    @recent_activity_groups  = load_recent_activity_groups
    @activity_group_rankings = build_rankings
    self
  end

  private

  def load_recent_transactions
    CurrencyTransaction
      .where(student_id: @story_group.student_memberships.select(:id))
      .includes(:student, :transactionable)
      .order(created_at: :desc)
      .limit(8)
  end

  def load_recent_activity_groups
    @story_group.activity_groups.order(created_at: :asc).limit(5)
  end

  def build_rankings
    students_by_id = @story_group.student_memberships.with_user.index_by(&:id)

    @recent_activity_groups.each_with_object({}) do |ag, result|
      category_ids = ag.activity_group_category_ids
      next if category_ids.empty?

      result[ag.id] = StudentsActivityGroupCategory
                      .joins(:activity_group_category)
                      .where(activity_group_category_id: category_ids)
                      .group(:student_id)
                      .sum('activity_group_categories.reward')
                      .sort_by { |_, v| -v }
                      .first(3)
                      .filter_map do |student_id, points|
                        (s = students_by_id[student_id]) && [s, points]
                      end
    end
  end
end
