# frozen_string_literal: true

require 'test_helper'

class BadgeTest < ActiveSupport::TestCase
  setup do
    @story_group = FactoryBot.create(:story_group)
  end

  test 'badge belongs to story group' do
    badge = Badge.new(story_group: @story_group, name: 'Totalny Kozak', description: 'Klasa sama w sobie')
    assert_equal @story_group, badge.story_group
  end

  test 'badge name validation' do
    badge = Badge.new(name: 'A' * 50, description: 'Too long name')
    assert badge.invalid?
    assert badge.errors[:name].any?
  end

  test 'badge description validation' do
    badge = Badge.new(name: 'Valid', description: 'A' * 300)
    assert badge.invalid?
    assert badge.errors[:description].any?
  end

  test 'badge saves with valid attributes' do
    badge = Badge.new(story_group: @story_group, name: 'Starter', description: 'A starter badge')
    assert badge.valid?
    assert badge.save
  end
end