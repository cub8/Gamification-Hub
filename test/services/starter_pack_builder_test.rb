# frozen_string_literal: true

require 'test_helper'

class StarterPackBuilderTest < ActiveSupport::TestCase
  setup do
    @story_group = FactoryBot.create(:story_group, owner: FactoryBot.create(:user, role: :teacher))
  end

  def build(pack: 'neutral', classes: 12, selection: {})
    StarterPackBuilder.new(story_group: @story_group, pack: pack, classes: classes,
                           selection: selection,).call
  end

  test 'creates the whole set in one go' do
    result = build

    assert_equal 5, @story_group.ranks.count
    assert_equal 6, @story_group.badges.count
    assert_equal 7, @story_group.items.count
    assert_equal 1, @story_group.activity_group_templates.count
    assert_equal 8, @story_group.activity_group_templates.first.categories.count
    assert_equal StarterPack.template_name,
                 @story_group.activity_group_templates.first.base_name
    assert_equal 5, result.ranks.size
  end

  test 'a template, not sheets' do
    build

    assert_equal 0, @story_group.activity_groups.count
  end

  test 'categories keep the preset order' do
    build

    assert_equal StarterPack.category_names,
                 @story_group.activity_group_templates.first.categories.map(&:didactic_description)
  end

  test 'wires item requirements to the ranks and badges it created' do
    build

    uczen  = @story_group.ranks.find_by(name: 'Uczeń')
    adept  = @story_group.ranks.find_by(name: 'Adept')
    expert = @story_group.ranks.find_by(name: 'Ekspert')

    plus_five = @story_group.items.find_by(name: '+5 minut do wejściówki')
    assert_nil plus_five.unlock_rank
    assert_equal adept, plus_five.min_rank_for_discount

    retake = @story_group.items.find_by(name: 'Poprawa wejściówki')
    assert_equal uczen, retake.unlock_rank
    assert_equal expert, retake.min_rank_for_discount

    safe = @story_group.items.find_by(name: 'Bezpieczna poprawa')
    assert_equal adept, safe.unlock_rank
    assert_equal ['Stała obecność', 'Iskra ciekawości'].sort,
                 safe.discount_badges.map(&:name).sort
  end

  test 'the 1up item is the only one buyable at zero lives' do
    build

    assert_equal ['1up: odzyskanie życia'],
                 @story_group.items.where(can_buy_at_0_lives: true).pluck(:name)
  end

  test 'skips the rows the teacher removed' do
    build(selection: {
            badges: { 0 => { keep: false } },
            items:  { 6 => { keep: false } },
            cats:   { 7 => { keep: false } },
          })

    assert_equal 5, @story_group.badges.count
    assert_equal 6, @story_group.items.count
    assert_equal 7, @story_group.activity_group_templates.first.categories.count
    assert_nil @story_group.badges.find_by(name: 'Bez skazy')
  end

  test 'an item whose required rank was removed loses the requirement' do
    build(selection: { ranks: { 1 => { keep: false } } })

    assert_equal 4, @story_group.ranks.count
    assert_nil @story_group.items.find_by(name: 'Poprawa wejściówki').unlock_rank
  end

  test 'honours retyped numbers' do
    build(selection: {
            ranks: { 1 => { value: '33' } },
            items: { 0 => { value: '7' } },
            cats:  { 0 => { value: '4' } },
          })

    assert_equal 33, @story_group.ranks.find_by(name: 'Uczeń').required_currency_value
    assert_equal 7, @story_group.items.find_by(name: '+5 minut do wejściówki').price
    assert_equal 4, @story_group.activity_group_templates.first.categories.first.reward
  end

  test 'a blank override falls back to the preset value' do
    build(selection: { items: { 0 => { value: '' } } })

    assert_equal 11, @story_group.items.find_by(name: '+5 minut do wejściówki').price
  end

  test 'refuses two ranks edited onto the same threshold' do
    error = assert_raises(StarterPackBuilder::InvalidSelection) do
      build(selection: { ranks: { 1 => { value: '40' } } })
    end

    assert_match(/tego samego progu/, error.message)
  end

  test 'leaves nothing behind when it refuses' do
    assert_no_difference ['Rank.count', 'Badge.count', 'Item.count'] do
      assert_raises(StarterPackBuilder::InvalidSelection) do
        build(selection: { ranks: { 1 => { value: '40' } } })
      end
    end
  end

  test 'accepts an externally-built preset instead of pack/classes' do
    preset = Struct.new(:ranks, :badges, :items, :templates).new(
      [StarterPack::Rank.new(index: 0, name: 'Importowana', threshold: 100, discount: 5, icon_glyph: 'chev1')],
      [],
      [],
      [],
    )

    result = StarterPackBuilder.new(story_group: @story_group, preset: preset).call

    assert_equal 1, @story_group.ranks.count
    assert_equal 'Importowana', @story_group.ranks.first.name
    assert_equal 1, result.ranks.size
  end

  test 'creates zero templates when the preset has none' do
    preset = Struct.new(:ranks, :badges, :items, :templates).new([], [], [], [])

    StarterPackBuilder.new(story_group: @story_group, preset: preset).call

    assert_equal 0, @story_group.activity_group_templates.count
  end

  test 'creates multiple templates when the preset has more than one' do
    category = StarterPack::Category.new(index: 0, didactic_description: 'Quiz', story_description: nil, reward: 3)
    preset = Struct.new(:ranks, :badges, :items, :templates).new(
      [], [], [],
      [
        StarterPack::TemplateGroup.new(index: 0, name: 'Laboratoria', categories: [category]),
        StarterPack::TemplateGroup.new(index: 1, name: 'Wykłady', categories: [category]),
      ],
    )

    result = StarterPackBuilder.new(story_group: @story_group, preset: preset).call

    assert_equal 2, @story_group.activity_group_templates.count
    assert_equal %w[Laboratoria Wykłady], @story_group.activity_group_templates.order(:id).map(&:base_name)
    assert_equal 2, result.categories.size
  end
end
