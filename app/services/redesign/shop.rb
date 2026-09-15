# frozen_string_literal: true

module Redesign
  # The group's offer, resolved once for one student. Mockup: viewShop() and
  # itemState(), js-expanded/30-main.js:87-98 and 10-core.js:15-31.
  #
  # All queries, so a service rather than a value — the same split ItemShelf,
  # RankLadder and BadgeShelf make. Everything comes from ONE load of the items
  # with their requirements preloaded and ONE load of the rank ladder.
  #
  # The three states are NOT re-derived here. Whether an item is sealed comes
  # from PurchaseEligibilityService and what it costs from
  # DiscountCalculatorService + PriceCalculatorService — the same two objects
  # ItemPurchaseService consults at the till. A second implementation of those
  # rules is exactly how a card ends up advertising a price the purchase then
  # refuses to honour.
  class Shop
    # Zone order is the mockup's, and it is a reading order: what you can have,
    # what you are working toward, what is still shut.
    ZONES = [
      [:afford, 'Stać cię teraz'],
      [:save,   'Zbierasz na to'],
      [:sealed, 'Zapieczętowane'],
    ].freeze

    Zone = Struct.new(:key, :label, :offers)

    def initialize(story_group:, student:)
      @story_group = story_group
      @student     = student
    end

    attr_reader :story_group, :student

    # Empty zones are dropped rather than rendered empty — the mockup's zone()
    # returns '' for them, and a dashed frame around nothing reads as a fault.
    def zones
      @zones ||= ZONES.filter_map do |key, label|
        found = offers.select { |offer| state_of(offer.item) == key }

        Zone.new(key: key, label: label, offers: found) if found.any?
      end
    end

    def any? = items.any?

    def size = items.size

    def balance = student.current_currency.to_i

    def total = student.total_currency.to_i

    def state_for(item) = state_of(item)

    def offer_for(item) = offers_by_item_id[item.id]

    # The student's own badges that carry a discount, for the head's sentence.
    # Not the items' discount_badges: this says what YOU bring to the shop.
    def discount_badges
      return @discount_badges if defined?(@discount_badges)

      discounted = student.badges.select { |badge| badge.discount.to_i.positive? }
      @discount_badges = discounted.sort_by { |badge| badge.name.to_s }
    end

    private

    def offers
      @offers ||= items.map { |item| build_offer(item) }
    end

    def offers_by_item_id = @offers_by_item_id ||= offers.index_by { |offer| offer.item.id }

    def build_offer(item)
      discount = item.discount_info_for(student)
      price    = PriceCalculatorService.new(price: item.price, discount: discount).calculate

      ItemOffer.new(card:     ItemCard.new(item, ranks: ranks),
                    price:    price,
                    discount: discount,
                    unmet:    unmet_for(item),
                    student:  student,)
    end

    # Mirrors itemState() (10-core.js:24): a requirement you fail beats a price
    # you cannot meet, because the price is not the thing standing in your way.
    def state_of(item)
      return :sealed if unmet_for(item).any?

      offers_by_item_id[item.id].price <= balance ? :afford : :save
    end

    # Rank first, then badges, then lives — the mockup's order, which is not
    # the order the service checks them in.
    KIND_ORDER = { rank: 0, badge: 1, lives: 2 }.freeze
    private_constant :KIND_ORDER

    def unmet_for(item)
      @unmet_for ||= {}
      @unmet_for[item.id] ||= eligibility_for(item).reasons
                                                   .sort_by { |reason| KIND_ORDER.fetch(reason.kind, 9) }
                                                   .map { |reason| requirement_for(reason) }
    end

    def requirement_for(reason)
      return RequirementPhrasing::LIVES if reason.kind == :lives

      RequirementPhrasing::Requirement.new(reason.kind, reason.record.name)
    end

    def eligibility_for(item)
      @eligibility_for ||= {}
      @eligibility_for[item.id] ||= PurchaseEligibilityService.new(student: student, item: item).call
    end

    def ranks
      @ranks ||= story_group.ranks.by_threshold.to_a
    end

    def items
      @items ||= story_group.items
                            .kept
                            .with_attached_icon
                            .includes(:unlock_rank, :min_rank_for_discount, :unlock_badges, :discount_badges)
                            .by_price
                            .to_a
    end
  end
end
