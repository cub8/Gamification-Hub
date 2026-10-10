# frozen_string_literal: true

class RankLadder
  Rung = Data.define(:rank, :holders, :gap_to_next, :next_threshold, :state, :progress,
                     :remaining,) do
    def done?    = state == :done
    def current? = state == :current
    def locked?  = state == :locked
    def next?    = state == :next
    def progressing? = !progress.nil?
  end

  attr_reader :story_group, :membership

  def initialize(story_group:, membership: nil)
    @story_group = story_group
    @membership  = membership
  end

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
  def student_totals = totals
  def collected = total

  def held
    return @held if defined?(@held)

    @held = membership && ranks.reverse.find { |rank| rank.required_currency_value <= total }
  end

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
