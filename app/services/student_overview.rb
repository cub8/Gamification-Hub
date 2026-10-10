# frozen_string_literal: true

class StudentOverview
  HAND = 3
  LEDGER = 6

  attr_reader :items, :student, :entries


  def initialize(student:)
    @student = student
  end

  def load
    @items      = load_items
    @entries    = ledger.entries.first(LEDGER)
    self
  end

  def story_group = @story_group ||= student.story_group

  def balance = student.current_currency.to_i

  def total = student.total_currency.to_i

  def lives = student.lives.to_i

  def rank      = student.rank
  def next_rank = student.next_rank

  def rank_progress
    return if next_rank.nil?

    floor  = rank&.required_currency_value.to_i
    target = next_rank.required_currency_value.to_i

    [total - floor, target - floor]
  end

  def missing_to_next_rank
    return if next_rank.nil?

    next_rank.required_currency_value.to_i - total
  end

  def badges = @badges ||= BadgeShelf.new(story_group: story_group, membership: student)

  def items_count = @items_count ||= student.students_items.count

  def affordable = shop.affordable

  def ledger = @ledger ||= CurrencyLedger.new(student: student)

  def ranking_place
    return @ranking_place if defined?(@ranking_place)

    @ranking_place = if StoryGroupPolicy.new(student.user, story_group).see_ranking_standings?
                       totals = story_group.student_memberships.pluck(:total_currency).map(&:to_i)
                       totals.sort.reverse.index(total) + 1
                     end
  end

  private

  def load_items
    student.students_items
           .includes(item: { icon_attachment: :blob })
           .order(created_at: :desc)
           .limit(HAND)
           .to_a
  end

  def shop = @shop ||= Shop.new(story_group: story_group, student: student)
end
