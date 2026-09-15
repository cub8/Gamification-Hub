# frozen_string_literal: true

module Redesign
  # Everything an item CARD has to show, in one place — so the teacher grid, the
  # form preview and (next) the shop and the student inventory cannot disagree
  # about what an item requires or what it is worth.
  #
  # Read-only and query-free: it reads associations the caller has already
  # loaded, which is why it is a value rather than a service. `ranks` is the
  # group's ladder, needed only by #max_discount; a caller that does not show a
  # discount ceiling can leave it out.
  #
  # The card's STATE (:afford / :save / :sealed) is not decided here. On the form
  # it is whichever tab the teacher pressed, and in the shop it will come from
  # PurchaseEligibilityService against a real student — two different questions,
  # neither of them a property of the item.
  class ItemCard
    include RequirementPhrasing

    def initialize(item, ranks: [])
      @item  = item
      @ranks = ranks
    end

    attr_reader :item, :ranks

    # Rank first, then badges in name order — the order the seal and the sealed
    # foot read them in.
    #
    # Only the requirements SOMEBODY CAN FAIL. A rank at threshold 0 is held by
    # every student from the moment they join (StoryGroupStudent#rank returns
    # the highest rung at or below their total), so gating on it gates nobody —
    # naming it on the card would put a lock on an item anyone can buy.
    #
    # Badges are never universally held, so they always gate.
    def requirements
      @requirements ||= [gating_rank_requirement, *badge_requirements].compact
    end

    # Whether this item can ever appear sealed to anyone.
    def requires? = requirements.any?

    # "Wymaga rangi Kapitan." — the sealed card's foot lists every one of these.
    def requirement_lines = requirement_lines_for(requirements)

    # The plate stamped across the artwork.
    def seal_label = seal_label_for(requirements.first)

    # The most any student could ever save on this item: the best rank discount
    # the item honours, plus every discount badge it lists, because a student
    # can hold all of them at once (DECISIONS.md:33).
    #
    # NOT the mockup's example() (30-item.js:20), which picks the rank at
    # max(unlockRank, discRank) — that exists to write one sample sentence about
    # one imagined student, and under-reports the ceiling this tag promises.
    #
    # Run through Discount so the number on the card is the number the shop will
    # actually charge: DiscountCalculatorService caps every total at
    # Discount::CAP_VALUE, and a card promising −80% when the till gives −50%
    # would be a lie told by the design.
    def max_discount
      @max_discount ||= Discount.new(rank_discount + badge_discount).value
    end

    # The rung that supplies #rank_discount, so the form's example sentence can
    # name it. Nil when the item honours no rank discount at all.
    def best_discount_rank
      return @best_discount_rank if defined?(@best_discount_rank)

      @best_discount_rank = eligible_ranks.max_by { |rank| rank.discount.to_i }
    end

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

    def discounts? = item.discount_badges.any? || item.min_rank_for_discount.present?

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

    # The item names a THRESHOLD, and a student gets their own rank's discount
    # once they are past it (DiscountCalculatorService#discount_from_rank). So
    # the ceiling is the best discount on the ladder at or above that threshold,
    # not the threshold rank's own.
    def rank_discount
      discounts = eligible_ranks.filter_map { |rank| rank.discount&.clamp(0, 100) }
      discounts.max.to_i
    end

    def eligible_ranks
      floor = item.min_rank_for_discount
      return [] if floor.nil?

      ranks.select { |rank| rank.required_currency_value.to_i >= floor.required_currency_value.to_i }
    end

    def badge_discount
      item.discount_badges.sum { |badge| badge.discount.to_i }
    end
  end
end
