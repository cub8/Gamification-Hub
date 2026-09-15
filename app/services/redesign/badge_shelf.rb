# frozen_string_literal: true

module Redesign
  # The badges of one group, resolved once for the whole page.
  #
  # Both badge screens and the form's preview ask the same questions — which
  # badges are there, how many students hold each, which ones the viewer has
  # earned, and which items lean on them — and every one of them is a query, so
  # this is a service rather than a value object, exactly like RankLadder.
  #
  # Everything comes from ONE load of the badges, ONE grouped count of the
  # awards, ONE pluck of the viewer's own, and ONE item query. Asking
  # `badge.students_badges.count` per card would be a query per card.
  class BadgeShelf
    # `earned` and `withdrawn` are only meaningful when the shelf was built for
    # a membership.
    #
    #   earned    — this student holds it, so the card shows its front
    #   withdrawn — soft-deleted, but held: it is off every list except this
    #               student's own deck, where it stays as history
    Slot = Struct.new(:badge, :holders, :earned, :withdrawn) do
      def earned?    = earned
      def withdrawn? = withdrawn
    end

    def initialize(story_group:, membership: nil)
      @story_group = story_group
      @membership  = membership
    end

    attr_reader :story_group, :membership

    # Alphabetical. For a student, any badge they hold that has since been
    # deleted is appended after the live ones — it is no longer part of what
    # there is to collect, but it is still theirs.
    def slots
      @slots ||= badges.map { |badge| slot_for(badge) } + withdrawn_slots
    end

    def any? = slots.any?

    # What there is to collect. Deliberately not `slots.size`: a student's
    # withdrawn badges are not part of "n z m".
    def size = badges.size

    # Counted against `size`, so it counts only badges still on the shelf: a
    # withdrawn one is no longer part of "n z m", or a student could be told
    # they have 1 of 2 while holding none of those two.
    def earned_count = slots.count { |slot| slot.earned? && !slot.withdrawn? }

    def total_students = story_group.student_memberships.count

    def holders_for(badge) = holders_by_badge_id[badge.id].to_i

    # Items that point at this badge, preloaded for the whole shelf. An item can
    # appear under two badges, and under one badge through both associations.
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

    # Only a student has these, and only for badges no longer on the shelf.
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

    # One grouped count for every badge in the group at once.
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
end
