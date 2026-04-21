# frozen_string_literal: true

require 'test_helper'

class BadgeTest < ActiveSupport::TestCase
  setup do
    @story_group = FactoryBot.create(:story_group)
  end

  test 'badge name validation' do
    badge = Badge.new(
      name:        'A' * 50,
      story_description: 'Too long name',
      didactic_description: 'Too long didactic description',
      discount:    10,
    )
    assert_equal true, badge.invalid?
    assert_equal true, badge.errors[:name].any?
  end

  test 'badge story description validation' do
    badge = Badge.new(
      name:        'Valid',
      story_description: 'A' * 300,
      didactic_description: 'Valid didactic description',
      discount:    10,
    )
    assert_equal true, badge.invalid?
    assert_equal true, badge.errors[:story_description].any?
  end

    test 'badge didactic description validation' do
    badge = Badge.new(
      name:        'Valid',
      story_description: 'Valid story description',
      didactic_description: 'A' * 300,
      discount:    10,
    )
    assert_equal true, badge.invalid?
    assert_equal true, badge.errors[:didactic_description].any?
  end

  test 'badge discount validation' do
    badge = Badge.new(
      name:        'Valid',
      story_description: 'Valid story description',
      didactic_description: 'Valid didactic description',
      discount:    -5,
    )
    assert_equal true, badge.invalid?
    assert_equal true, badge.errors[:discount].any?
  end

  test 'badge saves with valid attributes' do
    badge = Badge.new(
      story_group: @story_group,
      name:        'Starter',
      story_description: 'A starter badge',
      didactic_description: 'A didactic description for the starter badge',
      discount:    10,
    )
    assert_equal true, badge.valid?
    assert_equal true, badge.save
  end
end
