# frozen_string_literal: true

class ItemShelf
  DEFAULT_PRICE = 15

  Slot = Data.define(:item, :bought)

  attr_reader :story_group

  def initialize(story_group:)
    @story_group = story_group
  end

  def slots
    @slots ||= items.map { |item| Slot.new(item: item, bought: bought_by_item_id[item.id].to_i) }
  end

  def any? = slots.any?
  def size = items.size

  def ranks
    @ranks ||= story_group.ranks.by_threshold.to_a
  end

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

  def bought_by_item_id
    @bought_by_item_id ||= StudentsItem
                           .joins(:story_group_student)
                           .where(story_group_students: { story_group_id: story_group.id })
                           .group(:item_id)
                           .count
  end
end
