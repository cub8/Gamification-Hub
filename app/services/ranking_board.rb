# frozen_string_literal: true

class RankingBoard
  Row = Data.define(:place, :student, :rank, :mine) do
    def gap? = false
  end

  class GapRow
    def gap? = true
  end

  GAP = GapRow.new

  attr_reader :story_group, :membership

  def initialize(story_group:, membership: nil)
    @story_group = story_group
    @membership  = membership
  end

  def teacher? = membership.nil?
  def visible? = story_group.ranking_enabled?
  def participants_count = rows.size
  def any? = rows.any?

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

  def own_row = @own_row ||= rows.find(&:mine)

  def own_place
    return unless visible?

    own_row&.place
  end

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

  def rank_for(student)
    ladder.reverse_each.find { |rank| rank.required_currency_value.to_i <= student.total_currency.to_i }
  end

  def ladder
    @ladder ||= story_group.ranks.by_threshold.to_a
  end

  def sort_key(student)
    name = student.display_name.to_s
    [ActiveSupport::Inflector.transliterate(name).downcase, name, student.id]
  end
end
