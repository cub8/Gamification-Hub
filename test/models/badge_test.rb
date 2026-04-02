# frozen_string_literal: true

require 'test_helper'

class BadgeTest < ActiveSupport::TestCase
  setup do
    @story_group = FactoryBot.create(:story_group)
  end

  test 'badge name validation' do
    badge = Badge.new(
      name: 'A' * 50,
      description: 'Too long name',
      discount: 10,
      required_currency_value: 100
    )
    assert_equal true, badge.invalid?
    assert_equal true, badge.errors[:name].any?
  end

  test 'badge description validation' do
    badge = Badge.new(
      name: 'Valid',
      description: 'A' * 300,
      discount: 10,
      required_currency_value: 100)
    assert_equal true, badge.invalid?
    assert_equal true, badge.errors[:description].any?
  end

    test 'badge discount validation' do
    badge = Badge.new(
      name: 'Valid',
      description: 'Valid description',
      discount: -5,
      required_currency_value: 100)
    assert_equal true, badge.invalid?
    assert_equal true, badge.errors[:discount].any?
  end

    test 'badge required currency value validation' do
    badge = Badge.new(
      name: 'Valid',
      description: 'Valid description',
      discount: 10,
      required_currency_value: -100)
    assert_equal true, badge.invalid?
    assert_equal true, badge.errors[:required_currency_value].any?
  end

  test 'badge saves with valid attributes' do
    badge = Badge.new(
      story_group: @story_group,
      name: 'Starter',
      description: 'A starter badge',
      discount: 10,
      required_currency_value: 100
    )
    assert_equal true, badge.valid?
    assert_equal true, badge.save
  end
end
