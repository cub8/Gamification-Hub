# frozen_string_literal: true

require 'test_helper'

class BadgeTest < ActiveSupport::TestCase
  setup do
    @story_group = FactoryBot.create(:story_group)
  end

  test 'badge name validation' do
    badge = Badge.new(
      name:                 'A' * 51,
      story_description:    'Too long name',
      didactic_description: 'Too long didactic description',
      discount:             10,
    )
    assert_equal true, badge.invalid?
    assert_equal true, badge.errors[:name].any?
  end

  test 'badge story description validation' do
    badge = Badge.new(
      name:                 'Valid',
      story_description:    'A' * 300,
      didactic_description: 'Valid didactic description',
      discount:             10,
    )
    assert_equal true, badge.invalid?
    assert_equal true, badge.errors[:story_description].any?
  end

  test 'badge didactic description validation' do
    badge = Badge.new(
      name:                 'Valid',
      story_description:    'Valid story description',
      didactic_description: 'A' * 300,
      discount:             10,
    )
    assert_equal true, badge.invalid?
    assert_equal true, badge.errors[:didactic_description].any?
  end

  test 'badge discount validation' do
    badge = Badge.new(
      name:                 'Valid',
      story_description:    'Valid story description',
      didactic_description: 'Valid didactic description',
      discount:             -5,
    )
    assert_equal true, badge.invalid?
    assert_equal true, badge.errors[:discount].any?
  end

  test 'a badge needs a name and a rule, in Polish' do
    badge = Badge.new(story_group: @story_group, discount: 0)

    assert_predicate badge, :invalid?
    assert_equal 'Podaj nazwę odznaki.', badge.errors[:name].first
    assert_equal 'Napisz, jak zdobyć tę odznakę.', badge.errors[:didactic_description].first
  end

  test 'a glyph outside the badge presets is refused' do
    badge = FactoryBot.build(:badge, story_group: @story_group, icon_glyph: 'chev1')

    assert_predicate badge, :invalid?
    assert_equal 'Nieznana grafika.', badge.errors[:icon_glyph].first
  end

  # The same three states as Rank#art: a key wins over an attachment, and the
  # attachment is kept so a teacher can switch back.
  test 'art names the preset, the upload, or neither' do
    badge = FactoryBot.create(:badge, story_group: @story_group, icon_glyph: nil)
    assert_nil badge.art
    assert_not badge.upload?

    badge.icon.attach(io: Rails.root.join('test/fixtures/files/rank_art.png').open,
                      filename: 'art.png', content_type: 'image/png',)
    assert_equal :upload, badge.art
    assert_predicate badge, :upload?

    badge.update!(icon_glyph: 'crown')
    assert_equal 'crown', badge.art
    assert_predicate badge.icon, :attached?
  end

  test 'soft delete keeps the row and takes it off the kept scope' do
    badge = FactoryBot.create(:badge, story_group: @story_group)

    assert_no_difference('Badge.count') { badge.soft_delete! }

    assert_predicate badge.reload, :deleted?
    assert_empty @story_group.badges.kept
    assert_equal [badge], @story_group.badges.deleted.to_a
  end

  # A badge written before the rule became required must still be deletable.
  test 'soft delete does not run validations' do
    badge = FactoryBot.build(:badge, story_group: @story_group)
    badge.save!(validate: false)
    badge.update_column(:didactic_description, nil)

    assert_nothing_raised { badge.soft_delete! }
    assert_predicate badge.reload, :deleted?
  end

  test 'dependent items finds both sides, unlocking_items only one' do
    badge = FactoryBot.create(:badge, story_group: @story_group)
    unlocks = FactoryBot.create(:item, story_group: @story_group, name: 'Poprawa',
                                       unlock_badges: [badge],)
    discounts = FactoryBot.create(:item, story_group: @story_group, name: 'Zaliczenie',
                                         discount_badges: [badge],)

    assert_equal [unlocks, discounts].sort_by(&:id), badge.dependent_items.order(:id).to_a
    assert_equal [unlocks], badge.unlocking_items.to_a
  end

  test 'badge saves with valid attributes' do
    badge = Badge.new(
      story_group:          @story_group,
      name:                 'Starter',
      story_description:    'A starter badge',
      didactic_description: 'A didactic description for the starter badge',
      discount:             10,
    )
    assert_equal true, badge.valid?
    assert_equal true, badge.save
  end
end
