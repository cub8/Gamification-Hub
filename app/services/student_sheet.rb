# frozen_string_literal: true

class StudentSheet
  TABS = [
    ['badges', 'Odznaki'],
    ['items',  'Przedmioty'],
    ['hist',   'Historia waluty'],
  ].freeze

  DEFAULT_TAB = 'badges'

  class << self
    def tab_for(param)
      TABS.map(&:first).include?(param.to_s) ? param.to_s : DEFAULT_TAB
    end
  end

  def initialize(student:)
    @student = student
  end

  attr_reader :student

  def story_group = student.story_group

  def balance = student.current_currency.to_i
  def total   = student.total_currency.to_i
  def lives   = student.lives.to_i
  def rank      = student.rank
  def next_rank = student.next_rank

  def rank_progress
    return if next_rank.nil?

    floor = rank&.required_currency_value.to_i
    span  = next_rank.required_currency_value.to_i - floor

    return 100 if span <= 0

    (((total - floor).to_f / span) * 100).clamp(0, 100).round
  end

  def badges
    @badges ||= student.students_badges
                       .with_badge
                       .includes(badge: { icon_attachment: :blob })
                       .order(created_at: :desc, id: :desc)
                       .to_a
  end

  def purchases
    @purchases ||= student.students_items
                          .includes(item: { icon_attachment: :blob })
                          .order(created_at: :desc, id: :desc)
                          .to_a
  end

  def ledger = @ledger ||= CurrencyLedger.new(student: student)

  def count_for(tab)
    case tab
    when 'items' then purchases.size
    when 'hist'  then ledger.size
    else              badges.size
    end
  end
end
