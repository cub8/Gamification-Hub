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
