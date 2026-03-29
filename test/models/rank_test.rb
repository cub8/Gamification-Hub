# frozen_string_literal: true

require 'test_helper'

class RankTest < ActiveSupport::TestCase
  setup do
    @story_group = FactoryBot.create(:story_group)
  end

  test 'rank belongs to story group' do
    rank = Rank.new(story_group: @story_group, name: 'Gold', description: 'A gold rank')
    assert_equal @story_group, rank.story_group
  end

  test 'rank name validation' do
    rank = Rank.new(name: 'A' * 50, description: 'Too long name')
    assert rank.invalid?
    assert rank.errors[:name].any?
  end

  test 'rank description validation' do
    rank = Rank.new(name: 'Valid', description: 'A' * 300)
    assert rank.invalid?
    assert rank.errors[:description].any?
  end

  test 'rank saves with valid attributes' do
    rank = Rank.new(story_group: @story_group, name: 'Silver', description: 'A silver rank')
    assert rank.valid?
    assert rank.save
  end
end