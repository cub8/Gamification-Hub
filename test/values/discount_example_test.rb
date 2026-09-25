# frozen_string_literal: true

require 'test_helper'

# The example student on the item form. Randomised, so these assert the rules
# that must hold for EVERY pick rather than freezing one seed's answer — a
# frozen pick would pass while the rule behind it rotted.
class DiscountExampleTest < ActiveSupport::TestCase
  SEEDS = (1..25)

  setup do
    @story_group = FactoryBot.create(:story_group)
    @item = FactoryBot.create(:item, story_group: @story_group, price: 100)
  end

  def rank(name:, threshold:, discount:)
    FactoryBot.create(:rank, story_group: @story_group, name: name,
                             required_currency_value: threshold, discount: discount,)
  end

  def badge(name:, discount:)
    FactoryBot.create(:badge, story_group: @story_group, name: name, discount: discount)
  end

  def card
    ItemCard.new(@item.reload,
                 ranks:  @story_group.ranks.by_threshold.to_a,
                 badges: @story_group.badges.kept.by_name.to_a,)
  end

  def examples
    SEEDS.map { |seed| DiscountExample.new(card, random: Random.new(seed)) }
  end

  test 'it never names more than two badges' do
    5.times { |i| badge(name: "Odznaka #{i}", discount: 5) }

    sizes = examples.map { |example| example.badges.size }

    assert_operator sizes.max, :<=, DiscountExample::MAX_BADGES
  end

  test 'it names every badge there is when there are fewer than two' do
    only = badge(name: 'Nawigator', discount: 10)

    picked = examples.map(&:badges)

    assert_equal [[only]], picked.uniq
  end

  test 'it names no badges when the group has none' do
    rank(name: 'Kapitan', threshold: 100, discount: 15)

    picked = examples.map(&:badges)

    assert_equal [[]], picked.uniq
  end

  test 'it names no rank when the group has none' do
    badge(name: 'Nawigator', discount: 10)

    picked = examples.map(&:rank)

    assert_equal [nil], picked.uniq
  end

  # A rung below the floor qualifies for nothing, so an example student standing
  # there would be quoted a saving they would never get.
  test 'a floor keeps the example on a rung at or above it' do
    rank(name: 'Rekrut', threshold: 0, discount: 30)
    kapitan = rank(name: 'Kapitan', threshold: 100, discount: 10)
    rank(name: 'Admirał', threshold: 500, discount: 20)
    @item.update!(min_rank_for_discount: kapitan)

    names = examples.map { |example| example.rank.name }

    assert_equal %w[Admirał Kapitan], names.uniq.sort
  end

  # With no floor, holding one of the badges the item lists is the only way in.
  test 'without a floor the example holds one of the badges the item lists' do
    listed = badge(name: 'Nawigator', discount: 10)
    3.times { |i| badge(name: "Inna #{i}", discount: 5) }
    @item.discount_badges << listed

    held = examples.map { |example| example.badges.include?(listed) }

    assert_equal [true], held.uniq
  end

  # A floor is qualification enough, so the badges are free to be anybody's.
  test 'with a floor the listed badges are not forced into the example' do
    kapitan = rank(name: 'Kapitan', threshold: 100, discount: 10)
    listed = badge(name: 'Nawigator', discount: 10)
    3.times { |i| badge(name: "Inna #{i}", discount: 5) }
    @item.update!(min_rank_for_discount: kapitan)
    @item.discount_badges << listed

    held = examples.map { |example| example.badges.include?(listed) }

    assert_includes held, false
  end

  test 'the percentage is the sum of exactly what it names' do
    rank(name: 'Kapitan', threshold: 100, discount: 15)
    badge(name: 'Nawigator', discount: 10)
    badge(name: 'Mechanik', discount: 5)

    examples.each do |example|
      named = example.rank&.discount.to_i + example.badges.sum(&:discount)

      assert_equal named, example.percent
    end
  end

  test 'the percentage never exceeds what the till will give' do
    rank(name: 'Kapitan', threshold: 100, discount: 40)
    badge(name: 'Nawigator', discount: 40)
    badge(name: 'Mechanik', discount: 40)

    percents = examples.map(&:percent)

    assert_equal [Discount::CAP_VALUE], percents.uniq
  end

  # Naming one puts a name in the sentence and no number behind it.
  test 'it skips rungs and badges worth nothing' do
    rank(name: 'Rekrut', threshold: 0, discount: 0)
    kapitan = rank(name: 'Kapitan', threshold: 100, discount: 15)
    badge(name: 'Bez zniżki', discount: 0)
    nawigator = badge(name: 'Nawigator', discount: 10)

    ranks  = examples.map(&:rank)
    badges = examples.map(&:badges)

    assert_equal [kapitan], ranks.uniq
    assert_equal [[nawigator]], badges.uniq
  end

  test 'nothing in the group to discount with leaves no example to write' do
    empty    = examples.map(&:none?)
    percents = examples.map(&:percent)

    assert_equal [true], empty.uniq
    assert_equal [0], percents.uniq
  end
end
