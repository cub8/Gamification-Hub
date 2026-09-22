# frozen_string_literal: true

# One sheet's grading table: the visible columns, the students, and which
# cells have already paid out.
#
# Every cell on the screen asks two questions — is it awarded, and what does
# it add to this student's row total — and the table is columns x students,
# so both are answered from one preloaded set rather than per cell.
class GradeSheet
  def initialize(activity_group)
    @activity_group = activity_group
  end

  attr_reader :activity_group

  def story_group = activity_group.story_group

  # Hidden columns are out of the table entirely (DECISIONS.md:31). The
  # awards they already made stay on the students; they just take no new ones.
  def categories
    @categories ||= activity_group.activity_group_categories.visible.to_a
  end

  # Same order as the students list, for the same reason: it is the order the
  # teacher is reading off their own screen.
  def students
    @students ||= story_group.student_memberships.with_user.sort_by { |student| sort_key(student) }
  end

  def awarded?(student, category) = awarded_pairs.include?([category.id, student.id])

  # What this student has already collected from this sheet — the dark half
  # of the "Razem" column, the half that cannot change.
  def awarded_total(student)
    categories.sum { |category| awarded?(student, category) ? category.reward.to_i : 0 }
  end

  # The most one student can take away from this sheet.
  def max_reward = categories.sum { |category| category.reward.to_i }

  def gradeable? = categories.any? && students.any?

  private

  def awarded_pairs
    @awarded_pairs ||= StudentsActivityGroupCategory
                       .where(activity_group_category_id: categories.map(&:id))
                       .pluck(:activity_group_category_id, :student_id)
                       .to_set
  end

  # By the real name, which is what the sheet prints: a teacher scanning for
  # somebody looks for the name they know.
  def sort_key(student)
    name = student.full_name.to_s
    [ActiveSupport::Inflector.transliterate(name).downcase, name, student.id]
  end
end
