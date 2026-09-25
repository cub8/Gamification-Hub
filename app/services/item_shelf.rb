# frozen_string_literal: true

# The items of one group, resolved once for the whole page.
#
# All queries, so a service rather than a value object — the same split
# RankLadder and BadgeShelf make. Everything comes from ONE load of the items
# with their requirements preloaded and ONE grouped count of the purchases;
# asking `item.students_items.count` per card would be a query per card, and a
# card also names its rank and its badges.
class ItemShelf
  # What a new item costs before the teacher touches the field (30-item.js:14).
  # A default rather than a blank, because a shop item without a price is not
  # a draft of anything.
  DEFAULT_PRICE = 15

  Slot = Data.define(:item, :bought)

  def initialize(story_group:)
    @story_group = story_group
  end

  attr_reader :story_group

  # Cheapest first (30-lists.js:34). A teacher reads this list as a price
  # list, so price is the order, not the name.
  def slots
    @slots ||= items.map { |item| Slot.new(item: item, bought: bought_by_item_id[item.id].to_i) }
  end

  def any? = slots.any?
  def size = items.size

  # The ladder, for ItemCard#max_discount and for the form's rank selects.
  # Loaded here so the form and the preview share one copy.
  def ranks
    @ranks ||= story_group.ranks.by_threshold.to_a
  end

  # The group's badges, for ItemCard#max_discount. Every badge counts toward
  # a discount, whatever an item lists (DiscountCalculatorService), so this is
  # the whole set rather than any one item's — loaded once for the grid.
  def badges
    @badges ||= story_group.badges.kept.by_name.to_a
  end

  def card_for(item) = ItemCard.new(item, ranks: ranks, badges: badges)

  def bought_for(item) = bought_by_item_id[item.id].to_i

  private

  def items
    @items ||= story_group.items
                          .kept
                          .with_attached_icon
                          .includes(:unlock_rank, :min_rank_for_discount, :unlock_badges, :discount_badges)
                          .by_price
                          .to_a
  end

  # One grouped count for every item in the group at once. Scoped through the
  # memberships rather than off the items, so a row belonging to another
  # group's copy of the same item could never leak in.
  def bought_by_item_id
    @bought_by_item_id ||= StudentsItem
                           .joins(:story_group_student)
                           .where(story_group_students: { story_group_id: story_group.id })
                           .group(:item_id)
                           .count
  end
end
