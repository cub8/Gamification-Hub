# frozen_string_literal: true

require 'test_helper'

class RankTest < ActiveSupport::TestCase
  setup do
    @story_group = FactoryBot.create(:story_group)
  end

  test 'rank name validation' do
    rank = Rank.new(
      name:                    'A' * 50,
      discount:                10,
      required_currency_value: 100,
    )
    assert_equal true, rank.invalid?
    assert_equal true, rank.errors[:name].any?
  end

  test 'rank discount validation' do
    rank = Rank.new(
      name:                    'Valid',
      discount:                -5,
      required_currency_value: 100,
    )
    assert_equal true, rank.invalid?
    assert_equal true, rank.errors[:discount].any?
  end

  test 'rank required currency value validation' do
    rank = Rank.new(
      name:                    'Valid',
      discount:                10,
      required_currency_value: -100,
    )
    assert_equal true, rank.invalid?
    assert_equal true, rank.errors[:required_currency_value].any?
  end

  test 'a rank needs a name' do
    rank = Rank.new(story_group: @story_group, discount: 0, required_currency_value: 0)

    assert_predicate rank, :invalid?
    assert_equal 'Podaj nazwę rangi.', rank.errors[:name].first
  end

  # The threshold is what identifies a rung: two ranks at one threshold make
  # "which rank do I hold" arbitrary. The message names the rank in the way.
  test 'two ranks in a group cannot share a threshold' do
    FactoryBot.create(:rank, story_group: @story_group, name: 'Rekrut',
                             required_currency_value: 40,)
    clash = Rank.new(story_group: @story_group, name: 'Adept', discount: 0,
                     required_currency_value: 40,)

    assert_predicate clash, :invalid?
    assert_equal 'Ranga Rekrut ma już próg 40. Wybierz inny.',
                 clash.errors[:required_currency_value].first
  end

  test 'the same threshold in another group is fine' do
    FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 40)
    elsewhere = Rank.new(story_group: FactoryBot.create(:story_group), name: 'Adept',
                         discount: 0, required_currency_value: 40,)

    assert_predicate elsewhere, :valid?
  end

  test 'saving a rank unchanged does not clash with itself' do
    rank = FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 40)

    assert_predicate rank, :valid?
    assert rank.update(name: 'Adept')
  end

  # A group need not define a rank at 0 — its lowest rung may sit at 30, and a
  # student below it simply has no rank.
  test 'zero is a legal threshold but not a required one' do
    at_zero = FactoryBot.create(:rank, story_group: @story_group, name: 'Rekrut',
                                       required_currency_value: 0,)
    above = FactoryBot.create(:rank, story_group: @story_group, name: 'Adept',
                                     required_currency_value: 30,)

    assert_predicate at_zero, :starting?
    assert_not_predicate above, :starting?
  end

  test 'the preset must be one the rank picker offers' do
    rank = FactoryBot.build(:rank, story_group: @story_group, icon_glyph: 'rabbit')

    assert_predicate rank, :invalid?
    assert_equal 'Nieznana grafika.', rank.errors[:icon_glyph].first

    rank.icon_glyph = 'crown'
    assert_predicate rank, :valid?
  end

  # nil + attachment -> the upload; key + attachment -> the preset, upload kept.
  test 'art says which of the two images is in use' do
    rank = FactoryBot.create(:rank, story_group: @story_group, icon_glyph: nil)

    assert_nil rank.art

    rank.icon.attach(io: Rails.root.join('test/fixtures/files/rank_art.png').open,
                     filename: 'rank_art.png', content_type: 'image/png',)
    assert_equal :upload, rank.art
    assert_predicate rank, :upload?

    rank.icon_glyph = 'crown'
    assert_equal 'crown', rank.art
    assert_not_predicate rank, :upload?
  end

  test 'rank saves with valid attributes' do
    rank = Rank.new(
      story_group:             @story_group,
      name:                    'Silver',
      discount:                10,
      required_currency_value: 100,
    )
    assert_equal true, rank.valid?
    assert_equal true, rank.save
  end
end
