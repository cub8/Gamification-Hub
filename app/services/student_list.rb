# frozen_string_literal: true

class StudentList
  Row = Data.define(:student, :rank, :badge_count, :badge_ids, :item_ids) do
    def zero_lives? = student.lives.to_i.zero?
  end

  def initialize(story_group:)
    @story_group = story_group
  end

  attr_reader :story_group

  # By display name, so the order matches what the teacher is reading. Case
  # and diacritics folded, because "Łukasz" sorting after "Zofia" reads as a
  # bug to everyone but a byte comparator.
  def rows
    @rows ||= students.map { |student| row_for(student) }
                      .sort_by { |row| sort_key(row.student) }
  end

  def any? = rows.any?
  def size = rows.size

  # Students at 0 lives, for the sentence in the page head. They can still
  # buy, but only items marked "Można kupić przy 0 życiach".
  def zero_lives = rows.count(&:zero_lives?)

  # Options for the toolbar filters. Discarded items and badges are left out:
  # nobody can be sent to a screen they no longer have.
  def ranks = ladder

  def items
    @items ||= story_group.items.kept.by_price.to_a
  end

  def badges
    @badges ||= story_group.badges.kept.by_name.to_a
  end

  def unranked? = rows.any? { |row| row.rank.nil? }

  private

  def students
    @students ||= story_group.student_memberships.with_user.to_a
  end

  def row_for(student)
    Row.new(student:     student,
            rank:        rank_for(student),
            badge_count: badge_ids_by_student_id[student.id].size,
            badge_ids:   badge_ids_by_student_id[student.id],
            item_ids:    item_ids_by_student_id[student.id],)
  end

  # The highest rung at or below what the student has COLLECTED — the same
  # rule as StoryGroupStudent#rank, read off the ladder we already hold.
  def rank_for(student)
    ladder.reverse_each.find { |rank| rank.required_currency_value.to_i <= student.total_currency.to_i }
  end

  # Ascending, which is the order #rank_for walks backwards through.
  def ladder
    @ladder ||= story_group.ranks.by_threshold.to_a
  end

  # Every badge a student holds, discarded ones included, so the count column
  # keeps agreeing with what it always showed.
  def badge_ids_by_student_id
    @badge_ids_by_student_id ||= ids_by_student_id(StudentsBadge, :badge_id)
  end

  # One entry per purchase, so buying an item twice lists it once.
  def item_ids_by_student_id
    @item_ids_by_student_id ||= ids_by_student_id(StudentsItem, :item_id)
  end

  def ids_by_student_id(model, column)
    model.where(story_group_student_id: students.map(&:id))
         .pluck(:story_group_student_id, column)
         .group_by(&:first)
         .transform_values { |pairs| pairs.map(&:last).uniq }
         .tap { |grouped| grouped.default = [] }
  end

  # By the real name, which is what the list prints. The nickname sits in the
  # sub-line and is not what anyone scans this column for.
  def sort_key(student)
    name = student.full_name.to_s
    [ActiveSupport::Inflector.transliterate(name).downcase, name, student.id]
  end
end
