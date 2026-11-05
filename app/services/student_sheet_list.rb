# frozen_string_literal: true

class StudentSheetList
  Category = Data.define(:record, :earned) do
    def description = record.didactic_description
    def story       = record.story_description.presence
    def reward      = record.reward.to_i
    def earned?     = earned
  end

  Sheet = Data.define(:record, :categories) do
    def id         = record.id
    def name       = record.name
    def max_reward = categories.sum(&:reward)
    def earned     = categories.select(&:earned?).sum(&:reward)
    def complete?  = categories.all?(&:earned?)
  end

  attr_reader :story_group, :membership

  def initialize(story_group:, membership:)
    @story_group = story_group
    @membership  = membership
  end

  def sheets
    @sheets ||= sheet_records.filter_map do |record|
      categories = record.activity_group_categories.reject(&:hidden?).map do |category|
        Category.new(record: category, earned: earned_ids.include?(category.id))
      end

      Sheet.new(record: record, categories: categories) if categories.any?
    end
  end

  def any? = sheets.any?

  private

  def sheet_records
    @sheet_records ||= story_group.activity_groups.kept.newest_first.includes(:activity_group_categories).to_a
  end

  def earned_ids
    @earned_ids ||= membership.students_activity_group_categories.pluck(:activity_group_category_id).to_set
  end
end
