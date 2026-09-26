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

  # Whether this item can ever appear sealed to anyone.
  def requires? = requirements.any?

  # "Wymaga rangi Kapitan." — the sealed card's foot lists every one of these.
  def requirement_lines = requirement_lines_for(requirements)

  # The plate stamped across the artwork.
  def seal_label = seal_label_for(requirements.first)

  def max_discount
    @max_discount ||= Discount.new(raw_discount).value
  end

  # The sum BEFORE the till's cap. Everything above Discount::CAP_VALUE is
  # discount a teacher has configured and no student will ever receive, which
  # is worth saying out loud on the form.
  def raw_discount = rank_discount + badge_discount

  def capped? = raw_discount > Discount::CAP_VALUE

  def discount_rank_pool
    floor = item.min_rank_for_discount
    return ranks if floor.nil?

    ranks.select { |rank| rank.required_currency_value.to_i >= floor.required_currency_value.to_i }
  end

  # The rung that supplies #rank_discount, so the form's example sentence can
  # name it. Nil when no reachable rung saves anything — naming a rung worth
  # 0% would put a name in the sentence and no number behind it.
  def best_discount_rank
    return @best_discount_rank if defined?(@best_discount_rank)

    best = eligible_ranks.max_by { |rank| rank.discount.to_i }

    @best_discount_rank = best if best&.discount.to_i.positive?
  end

  # Badges worth naming in that sentence: the ones actually adding to the
  # ceiling, in the order gh_and_list will read them.
  def discount_badges
    return @discount_badges if defined?(@discount_badges)

    earning = badges.select { |badge| badge.discount.to_i.positive? }
    @discount_badges = earning.sort_by { |badge| badge.name.to_s }
  end

  # The two halves as GROUP facts, independent of this item's configuration —
  # what the live preview needs to recompute the ceiling as the teacher types,
  # since neither is readable off a chip or a single select option.
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

  # "Zniżki do −30%", or nothing when the item honours no discount at all.
  def discount_label
    return if max_discount.zero?

    "Zniżki do −#{max_discount}%"
  end

  # The teacher grid's chips (30-lists.js:35). Requirements read as locks
  # there; the discount is a flag rather than a number, because the list is
  # about what an item IS, not what any one student would pay.
  def lock_labels
    requirements.map { |requirement| requirement.rank? ? "Od rangi #{requirement.name}" : requirement.name }
  end

  # "Does anybody pay less than the price on this card?" — NOT "did the teacher
  # configure a discount". The two came apart once the till turned out to
  # discount unconfigured items for everyone, and it is the first question the
  # grid is really asking: a flag that stayed dark on an item selling below
  # list price would be the same lie in a smaller place.
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

  # The whole group, not item.discount_badges: the till counts every badge the
  # student holds, and a qualifying student may hold all of them. What the item
  # lists decides WHO gets a discount, never how big it is.
  def badge_discount = badges_discount
end
