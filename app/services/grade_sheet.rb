# frozen_string_literal: true

class GradeSheet
  def initialize(activity_group)
    @activity_group = activity_group
  end

  attr_reader :activity_group

  def story_group = activity_group.story_group

  def categories
    @categories ||= activity_group.activity_group_categories.visible.to_a
  end

  def students
    @students ||= story_group.student_memberships.with_user.sort_by { |student| sort_key(student) }
  end

  def awarded?(student, category) = awarded_pairs.include?([category.id, student.id])

  def awarded_total(student)
    categories.sum { |category| awarded?(student, category) ? category.reward.to_i : 0 }
  end

  def max_reward = categories.sum { |category| category.reward.to_i }

  def gradeable? = categories.any? && students.any?

  private

  def awarded_pairs
    @awarded_pairs ||= StudentsActivityGroupCategory
                       .where(activity_group_category_id: categories.map(&:id))
                       .pluck(:activity_group_category_id, :student_id)
                       .to_set
  end

  def sort_key(student)
    name = student.full_name.to_s
    [ActiveSupport::Inflector.transliterate(name).downcase, name, student.id]
  end
end
