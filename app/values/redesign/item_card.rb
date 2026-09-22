# frozen_string_literal: true

module Redesign
  # Everything an item CARD has to show, in one place — so the teacher grid, the
  # form preview and (next) the shop and the student inventory cannot disagree
  # about what an item requires or what it is worth.
  #
  # Read-only and query-free: it reads associations the caller has already
  # loaded, which is why it is a value rather than a service. `ranks` is the
  # group's ladder and `badges` its badges; both are needed only by
  # #max_discount, so a caller that shows no discount ceiling can leave them out
  # — Redesign::Shop does, because it always has a real Discount for the student
  # standing in front of it.
  #
  # The card's STATE (:afford / :save / :sealed) is not decided here. On the form
  # it is whichever tab the teacher pressed, and in the shop it will come from
  # PurchaseEligibilityService against a real student — two different questions,
  # neither of them a property of the item.
  class ItemCard
    include RequirementPhrasing

    def initialize(item, ranks: [], badges: [])
      @item   = item
      @ranks  = ranks
      @badges = badges
    end

    attr_reader :item, :ranks, :badges

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

    # The most any student could ever save on this item.
    #
    # This MIRRORS DiscountCalculatorService, which is the till, and the till is
    # more generous than the item's own configuration suggests in two ways:
    #
    #   * an item that names no discount conditions discounts for EVERYONE
    #     (discount_calculator_service.rb:31), and
    #   * the amount is the student's own rank discount plus every badge they
    #     hold — not only the badges this item lists (:33-39).
    #
    # So the badge half is always the whole group, and the rank half is narrowed
    # only by a floor standing on its own; see #eligible_ranks.
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
      @max_discount ||= Discount.new(raw_discount).value
    end

    # The sum BEFORE the till's cap. Everything above Discount::CAP_VALUE is
    # discount a teacher has configured and no student will ever receive, which
    # is worth saying out loud on the form.
    def raw_discount = rank_discount + badge_discount

    def capped? = raw_discount > Discount::CAP_VALUE

    # The rungs Redesign::DiscountExample may put its example student on.
    #
    # Deliberately NOT #eligible_ranks. That one answers "which rungs could a
    # qualifying student be standing on", and as soon as a badge can let them in
    # the answer is the whole ladder — right for a ceiling, unsafe for ONE
    # sampled student, who would then be named on a rung below the floor with no
    # badge to qualify them. Standing at or above the floor always qualifies.
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

    # A student gets their OWN rank's discount once they qualify at all
    # (DiscountCalculatorService#discount_from_rank), so the ceiling is the best
    # discount among the rungs a qualifying student could be standing on.
    #
    # The best one, not the highest rung's: which rung you stand on is decided
    # by how much you have COLLECTED (StoryGroupStudent#rank), so a low rung
    # with a fat discount is reachable simply by having collected less. A ladder
    # of Rekrut −30% at 0 and Kapitan −10% at 100 tops out at 30%, held by
    # everyone below 100.
    def rank_discount
      discounts = eligible_ranks.filter_map { |rank| rank.discount&.clamp(0, 100) }
      discounts.max.to_i
    end

    # Which rungs a qualifying student could hold.
    #
    # A floor standing ALONE is the only thing that narrows this: there, the
    # single way in is to be at or above it. As soon as the item also lists
    # discount badges, holding one of them qualifies a student of any rank
    # (discount_calculator_service.rb:29) — and with no conditions at all
    # everyone qualifies — so the whole ladder is reachable either way.
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
end
