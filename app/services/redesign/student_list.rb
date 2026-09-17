# frozen_string_literal: true

module Redesign
  # The students of one group, resolved once for the whole page.
  #
  # The teacher's list shows a rank and a badge count beside every name, and
  # both are the kind of thing that turns into a query per row if a view asks
  # the record for it — StoryGroupStudent#rank runs a query, and it is memoised
  # per record, which does nothing for a list. So the ladder is loaded once and
  # each student's rung is resolved in Ruby, and the badge counts come from one
  # grouped count.
  #
  # A service rather than a value: it does the loading. Same split as ItemShelf
  # and BadgeShelf.
  class StudentList
    Row = Struct.new(:student, :rank, :badge_count) do
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

    private

    def students
      @students ||= story_group.student_memberships.with_user.to_a
    end

    def row_for(student)
      Row.new(student:     student,
              rank:        rank_for(student),
              badge_count: badges_by_student_id[student.id].to_i,)
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

    def badges_by_student_id
      @badges_by_student_id ||= StudentsBadge
                                .where(story_group_student_id: students.map(&:id))
                                .group(:story_group_student_id)
                                .count
    end

    def sort_key(student)
      name = student.display_name.to_s
      [ActiveSupport::Inflector.transliterate(name).downcase, name, student.id]
    end
  end
end
