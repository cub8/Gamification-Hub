# frozen_string_literal: true

class ItemCard
  include RequirementPhrasing

  def initialize(item, ranks: [], badges: [])
    @item   = item
    @ranks  = ranks
    @badges = badges
  end

  attr_reader :item, :ranks, :badges

  def requirements
    @requirements ||= [gating_rank_requirement, *badge_requirements].compact
  end

  def requires? = requirements.any?

  def requirement_lines = requirement_lines_for(requirements)

  def seal_label = seal_label_for(requirements.first)

  def max_discount
    @max_discount ||= Discount.new(raw_discount).value
  end

  def raw_discount = rank_discount + badge_discount

  def capped? = raw_discount > Discount::CAP_VALUE

  def discount_rank_pool
    floor = item.min_rank_for_discount
    return ranks if floor.nil?

    ranks.select { |rank| rank.required_currency_value.to_i >= floor.required_currency_value.to_i }
  end

  def best_discount_rank
    return @best_discount_rank if defined?(@best_discount_rank)

    best = eligible_ranks.max_by { |rank| rank.discount.to_i }

    @best_discount_rank = best if best&.discount.to_i.positive?
  end

  def discount_badges
    return @discount_badges if defined?(@discount_badges)

    earning = badges.select { |badge| badge.discount.to_i.positive? }
    @discount_badges = earning.sort_by { |badge| badge.name.to_s }
  end

  def ladder_discount
    discounts = ranks.filter_map { |rank| rank.discount&.clamp(0, 100) }
    discounts.max.to_i
  end

  def ladder_discount_rank
    return @ladder_discount_rank if defined?(@ladder_discount_rank)

    best = ranks.max_by { |rank| rank.discount.to_i }

    @ladder_discount_rank = best if best&.discount.to_i.positive?
  end

  def badges_discount = badges.sum { |badge| badge.discount.to_i }

  def discount_label
    return if max_discount.zero?

    "Zniżki do −#{max_discount}%"
  end

  def lock_labels
    requirements.map { |requirement| requirement.rank? ? "Od rangi #{requirement.name}" : requirement.name }
  end

  def discounts? = max_discount.positive?

  def zero_lives? = item.can_buy_at_0_lives.present?

  private

  def gating_rank_requirement
    rank = item.unlock_rank
    return if rank.nil? || rank.starting?

    Requirement.new(:rank, rank.name)
  end

  def badge_requirements
    sorted = item.unlock_badges.sort_by { |badge| badge.name.to_s }
    sorted.map { |badge| Requirement.new(:badge, badge.name) }
  end

  def rank_discount
    discounts = eligible_ranks.filter_map { |rank| rank.discount&.clamp(0, 100) }
    discounts.max.to_i
  end

  def eligible_ranks
    floor = item.min_rank_for_discount
    return ranks if floor.nil? || item.discount_badges.any?

    ranks.select { |rank| rank.required_currency_value.to_i >= floor.required_currency_value.to_i }
  end

  def badge_discount = badges_discount
end
