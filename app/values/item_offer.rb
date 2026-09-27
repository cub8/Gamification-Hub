# frozen_string_literal: true

class ItemOffer
  include RequirementPhrasing

  RankProgress = Data.define(:collected, :target, :rank_name)

  class << self
    def preview(card) = new(card: card, unmet: card.requirements)
  end

  def initialize(card:, price: nil, discount: nil, unmet: [], student: nil)
    @card     = card
    @price    = price
    @discount = discount
    @unmet    = unmet
    @student  = student
  end

  attr_reader :card, :discount, :unmet, :student

  def item = card.item

  def list_price = item.price.to_i

  def price = @price || list_price

  def discounted? = price < list_price

  def zero_lives? = card.zero_lives?

  def seal_label = seal_label_for(unmet.first)

  def requirement_lines = requirement_lines_for(unmet)

  def discount_label
    return card.discount_label if discount.nil?
    return if discount.value.zero?

    "−#{discount.value}% #{discount_source}"
  end

  def rank_progress
    rank = unmet.find(&:rank?) && item.unlock_rank
    return if rank.nil? || student.nil?

    target = rank.required_currency_value.to_i
    return if target <= 0

    RankProgress.new(student.total_currency.to_i, target, rank.name)
  end

  private

  def discount_source
    return 'za rangę i odznaki' if rank_discount? && badge_discount?
    return 'za rangę'           if rank_discount?

    'za odznaki'
  end

  def rank_discount? = student&.rank&.discount.to_i.positive?

  def badge_discount?
    return false if student.nil?

    total = student.badges.sum { |badge| badge.discount.to_i }
    total.positive?
  end
end
