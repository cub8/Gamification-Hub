# frozen_string_literal: true

module Redesign
  # The rank ladder of one group, resolved once for the whole page.
  #
  # Both rank screens and the form's live preview ask the same questions —
  # which rungs are there, how many students stand on each, how far apart they
  # are, and where the viewer stands — and every one of them is a query, so this
  # is a service rather than a value object.
  #
  # Everything is computed from ONE load of the ranks and ONE pluck of the
  # memberships' totals. Asking each rank for its holders would be a query per
  # rung, and StoryGroupStudent#rank is itself a query per call.
  class RankLadder
    # `state` is only meaningful when the ladder was built for a membership.
    #
    #   :done    — passed
    #   :current — the rank the student holds
    #   :next    — the first rung, when the student holds NO rank yet. The
    #              mockup has no such state (rankIdx falls back to index 0, so
    #              its student always holds something), but a group need not
    #              define a rank at 0, and then progress has nowhere else to go.
    #   :locked  — still out of reach
    Rung = Struct.new(:rank, :holders, :gap_to_next, :next_threshold, :state, :progress,
                      :remaining,) do
      def done?    = state == :done
      def current? = state == :current
      def locked?  = state == :locked
      def next?    = state == :next

      # The two states that show a progress bar towards something.
      def progressing? = !progress.nil?
    end

    def initialize(story_group:, membership: nil)
      @story_group = story_group
      @membership  = membership
    end

    attr_reader :story_group, :membership

    # Ascending by threshold. Every screen reverses this for display — the
    # mockup puts the highest rung on top (30-lists.js:26, 30-sp.js:22) and its
    # form preview does the same with `flex-direction: column-reverse`.
    def rungs
      @rungs ||= ranks.each_with_index.map do |rank, index|
        Rung.new(rank:           rank,
                 holders:        holders_by_rank_id[rank.id].to_i,
                 gap_to_next:    gap_after(index),
                 next_threshold: ranks[index + 1]&.required_currency_value,
                 state:          state_for(rank),
                 progress:       progress_for(rank),
                 remaining:      remaining_for(rank),)
      end
    end

    def descending = rungs.reverse

    def any? = ranks.any?

    def size = ranks.size

    def total_students = totals.size

    # Every student's lifetime total, for the form preview: it recomputes who
    # would move rung as you type, and needs the same numbers this bucketed the
    # holder counts with.
    def student_totals = totals

    # What the viewing student has collected. Zero without a membership.
    def collected = total

    # The rank the viewing student holds, or nil — either because they are below
    # the lowest threshold or because the group has no ranks at all. Mirrors
    # StoryGroupStudent#rank without re-querying.
    def held
      return @held if defined?(@held)

      @held = membership && ranks.reverse.find { |rank| rank.required_currency_value <= total }
    end

    # Items that would break if this rank were deleted. Preloaded for the whole
    # ladder; an item may appear under two different rungs, since Item has two
    # rank associations.
    def dependent_items(rank)
      dependent_items_by_rank_id[rank.id] || []
    end

    private

    def ranks
      @ranks ||= story_group.ranks.with_attached_icon.by_threshold.to_a
    end

    def totals
      @totals ||= story_group.student_memberships.pluck(:total_currency).map(&:to_i)
    end

    def total = @total ||= membership&.total_currency.to_i

    # One pass over the students, bucketed by the highest rung they reach.
    # Students below every threshold fall out, which is the point.
    def holders_by_rank_id
      @holders_by_rank_id ||= totals.filter_map { |value| rank_at(value)&.id }
                                    .tally
    end

    def rank_at(value)
      ranks.reverse.find { |rank| rank.required_currency_value <= value }
    end

    def gap_after(index)
      following = ranks[index + 1]
      return if following.nil?

      following.required_currency_value - ranks[index].required_currency_value
    end

    def state_for(rank)
      return if membership.nil?
      return :next if held.nil? && rank == ranks.first
      return :locked if held.nil?

      if rank.required_currency_value < held.required_currency_value then :done
      elsif rank == held                                             then :current
      else                                                                :locked
      end
    end

    # [collected, needed] for the bar, or nil where there is nothing to show:
    # a passed rung, a locked rung above the one you are working toward, and the
    # top rung once you are standing on it.
    def progress_for(rank)
      case state_for(rank)
      when :next    then [total, rank.required_currency_value]
      when :current then progress_to_next(rank)
      end
    end

    def progress_to_next(rank)
      following = ranks[ranks.index(rank) + 1]
      return if following.nil?

      span = following.required_currency_value - rank.required_currency_value
      [total - rank.required_currency_value, span]
    end

    # "Brakuje N" — how much more this rung needs. Only for rungs out of reach.
    def remaining_for(rank)
      return unless %i[locked next].include?(state_for(rank))

      rank.required_currency_value - total
    end

    def dependent_items_by_rank_id
      @dependent_items_by_rank_id ||= begin
        items = Item.where(unlock_rank: ranks).or(Item.where(min_rank_for_discount: ranks)).to_a

        ranks.to_h do |rank|
          [rank.id,
           items.select do |item|
             item.unlock_rank_id == rank.id || item.min_rank_for_discount_id == rank.id
           end,]
        end
      end
    end
  end
end
