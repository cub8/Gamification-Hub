# frozen_string_literal: true

module Redesign
  # "Ranking" (mockup #/t/ranking and #/s/ranking): one group's students ordered
  # by what they have COLLECTED, not by what they can still spend. Both personas
  # read the same board; who is asking decides how much of it comes back.
  #
  # A service rather than a value: it loads. Same split as RankLadder and
  # StudentList, and the same trick against N+1 — the rank ladder is fetched
  # once and each student's rung resolved in Ruby, because StoryGroupStudent#rank
  # is a query per record and memoised per record, which does nothing for a list.
  class RankingBoard
    # `place` is shared by ties; `mine` is only ever true for the viewer, so the
    # teacher's board carries no self-highlight (mockup: `mine = stu && …`).
    Row = Struct.new(:place, :student, :rank, :mine) do
      def gap? = false
    end

    # The ellipsis row that stands in for everyone the podium hides. It renders
    # as a real row with two cells, deliberately under-filling the grid, so the
    # view asks every row whether it is one rather than checking its class.
    class GapRow
      def gap? = true
    end

    GAP = GapRow.new

    def initialize(story_group:, membership: nil)
      @story_group = story_group
      @membership  = membership
    end

    attr_reader :story_group, :membership

    # Nil for a teacher. The view forks on it, exactly as ranks/index does.
    def teacher? = membership.nil?

    # Whether the teacher has turned the board on for students. The teacher's
    # own view never depends on it — they always see everyone.
    def visible? = story_group.ranking_enabled?

    def participants_count = rows.size

    def any? = rows.any?

    # Standard competition ranking: equal totals share a place and the next one
    # skips, so 40/40/10 gives 1, 1, 3 (DECISIONS.md:36).
    #
    # Ties still need an order to render in, and `total_currency DESC` alone
    # leaves it to the database. Sorted by folded display name inside a tie, the
    # same key StudentList uses, so the same two students never swap places
    # between two loads of the same page.
    def rows
      @rows ||= begin
        ordered = students.sort_by { |student| [-student.total_currency.to_i, *sort_key(student)] }
        place   = 0
        last    = nil

        ordered.each_with_index.map do |student, index|
          total = student.total_currency.to_i
          if total != last
            place = index + 1
            last  = total
          end

          Row.new(place, student, rank_for(student), student.id == membership&.id)
        end
      end
    end

    # The viewer's own row, and nil for a teacher: with no membership no row is
    # ever `mine`, so this needs no guard of its own.
    def own_row = @own_row ||= rows.find(&:mine)

    # The viewer's place, or nil when they are not entitled to know it. The
    # mockup reads `me.pos` before branching on visibility (30-rk.js:36); that
    # is harmless against fake data and wrong for a server, which should not
    # hand out a place the student is not allowed to see.
    def own_place
      return unless visible?

      own_row&.place
    end

    # What this viewer actually gets. A teacher gets everyone; so does a student
    # once the group is on "Pełny ranking". Podium mode gives the top three,
    # then a Gap and the student's own row when they are not already on it.
    def visible_rows
      return rows if teacher? || story_group.ranking_full?
      return [] unless visible?

      podium = rows.select { |row| row.place <= 3 }
      mine   = own_row
      return podium if mine.nil? || mine.place <= 3

      podium + [GAP, mine]
    end

    private

    def students
      @students ||= story_group.student_memberships.with_user.to_a
    end

    # The highest rung at or below what the student has collected — the same
    # rule as StoryGroupStudent#rank, read off the ladder we already hold.
    def rank_for(student)
      ladder.reverse_each.find { |rank| rank.required_currency_value.to_i <= student.total_currency.to_i }
    end

    # Ascending, which is the order #rank_for walks backwards through.
    def ladder
      @ladder ||= story_group.ranks.by_threshold.to_a
    end

    def sort_key(student)
      name = student.display_name.to_s
      [ActiveSupport::Inflector.transliterate(name).downcase, name, student.id]
    end
  end
end
