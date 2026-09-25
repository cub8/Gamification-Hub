# frozen_string_literal: true

# One plausible student, for the item form's discount example.
#
# The sentence used to name the whole group — every rank-topping rung and
# every badge at once — which is what the ceiling is made of but reads as an
# impossible completionist and runs off the line in a group with eight badges.
# This picks somebody believable instead: one rank, at most two badges.
#
# THE PICK MUST QUALIFY. A student who does not meet the item's discount
# conditions saves nothing, so a sentence quoting a percentage for them would
# be false — the same family of lie as the ceiling that used to say
# "Bez zniżek" about an item selling at 40% off. #pick_rank and #forced_badge
# below each guarantee one of the two ways in
# (DiscountCalculatorService#eligible_for_discount?).
#
# Random by design, and re-picked on every render of the form: the point is
# that it is AN example, not the example.
#
# The randomness is ONE shuffle, exposed as #rank_order / #badge_order and
# handed to item_form_controller, which walks it under the same rule when the
# teacher edits the conditions. Sampling here and shuffling separately for the
# browser would be two draws, and the two sides would name different students.
#
# The orders are lists of NAMES, because names are all the browser has on a
# chip. Two badges sharing a name would be ambiguous here — and on every other
# screen that names one.
class DiscountExample
  # Two is enough to show that badge discounts stack, and short enough to read.
  MAX_BADGES = 2

  def initialize(card, random: Random.new)
    @card   = card
    @random = random
  end

  attr_reader :card, :random

  # The draw both sides walk. Every rank and every badge in the group, so the
  # browser can re-pick under conditions the server never saw.
  def rank_order = @rank_order ||= card.ranks.map(&:name).shuffle(random: random)

  def badge_order = @badge_order ||= card.badges.map(&:name).shuffle(random: random)

  def rank = pick.first

  def badges = pick.last

  # Through Discount, so an example can never quote a saving the till refuses.
  def percent
    @percent ||= Discount.new(rank&.discount.to_i + badges.sum { |badge| badge.discount.to_i }).value
  end

  # No rank worth naming and no badge worth naming: there is no example to
  # write, and the maximum line beneath says everything there is to say.
  def any? = percent.positive?

  def none? = !any?

  private

  def pick
    @pick ||= [pick_rank, pick_badges]
  end

  # From the rungs at or above the floor (ItemCard#discount_rank_pool), which
  # is one of the two ways to qualify — and the only one available when the
  # item lists no discount badges.
  #
  # Rungs worth 0% are skipped: naming one puts a name in the sentence and no
  # number behind it.
  def pick_rank
    pool    = card.discount_rank_pool.select { |rank| rank.discount.to_i.positive? }
    earning = pool.index_by { |rank| rank.name.to_s }
    name    = rank_order.find { |candidate| earning.key?(candidate) }

    earning[name]
  end

  def pick_badges
    picked  = [forced_badge_name].compact
    earning = card.discount_badges.index_by { |badge| badge.name.to_s }

    badge_order.each do |candidate|
      break if picked.size >= MAX_BADGES

      picked << candidate if earning.key?(candidate) && picked.exclude?(candidate)
    end

    by_name = card.badges.index_by { |badge| badge.name.to_s }
    records = picked.filter_map { |name| by_name[name] }

    records.sort_by { |badge| badge.name.to_s }
  end

  # With no floor set, holding one of the badges the item lists is the ONLY
  # way to qualify, so the example student has to hold one. A floor makes the
  # rank enough and leaves the badges free.
  def forced_badge_name
    return if card.item.min_rank_for_discount.present?

    listed = card.item.discount_badges.map { |badge| badge.name.to_s }
    return if listed.empty?

    listed  = listed.to_set
    earning = card.discount_badges.map { |badge| badge.name.to_s }
    earning = earning.to_set

    badge_order.find { |name| listed.include?(name) && earning.include?(name) } ||
      badge_order.find { |name| listed.include?(name) }
  end
end
