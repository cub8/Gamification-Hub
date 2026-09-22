# frozen_string_literal: true

class BadgeShelf
  Slot = Data.define(:badge, :holders, :earned, :withdrawn) do
    def earned?    = earned
    def withdrawn? = withdrawn
  end

  def initialize(story_group:, membership: nil)
    @story_group = story_group
    @membership  = membership
  end

  attr_reader :story_group, :membership

  def slots
    @slots ||= badges.map { |badge| slot_for(badge) } + withdrawn_slots
  end

  def any? = slots.any?

  def size = badges.size

  def earned_count = slots.count { |slot| slot.earned? && !slot.withdrawn? }

  def total_students = story_group.student_memberships.count

  def holders_for(badge) = holders_by_badge_id[badge.id].to_i

  def dependent_items(badge)
    dependent_items_by_badge_id[badge.id] || []
  end

  private

  def badges
    @badges ||= story_group.badges.kept.with_attached_icon.by_name.to_a
  end

  def slot_for(badge)
    Slot.new(badge:     badge,
             holders:   holders_by_badge_id[badge.id].to_i,
             earned:    earned_ids.include?(badge.id),
             withdrawn: false,)
  end

  def withdrawn_slots
    return [] if membership.nil?

    live = badges.map(&:id)

    story_group.badges.deleted.where(id: earned_ids - live).with_attached_icon.by_name.map do |badge|
      Slot.new(badge:     badge,
               holders:   holders_by_badge_id[badge.id].to_i,
               earned:    true,
               withdrawn: true,)
    end
  end

  def holders_by_badge_id
    @holders_by_badge_id ||= StudentsBadge
                             .joins(:story_group_student)
                             .where(story_group_students: { story_group_id: story_group.id })
                             .group(:badge_id)
                             .count
  end

  def earned_ids
    @earned_ids ||= membership ? membership.students_badges.pluck(:badge_id) : []
  end

  def dependent_items_by_badge_id
    @dependent_items_by_badge_id ||= begin
      ids = slots.map { |slot| slot.badge.id }
      pairs = ItemsUnlockBadge.where(badge_id: ids).pluck(:badge_id, :item_id) +
              ItemsMinBadgesForDiscount.where(badge_id: ids).pluck(:badge_id, :item_id)
      items = Item.where(id: pairs.map(&:last).uniq).order(:name).index_by(&:id)

      pairs.group_by(&:first).transform_values do |group|
        group.filter_map { |(_, item_id)| items[item_id] }
             .uniq
             .sort_by(&:name)
      end
    end
  end
end
