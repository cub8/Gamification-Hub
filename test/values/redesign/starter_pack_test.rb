# frozen_string_literal: true

require 'test_helper'

class Redesign::StarterPackTest < ActiveSupport::TestCase
  Pack = Redesign::StarterPack

  test 'the categories add up to one class maximum' do
    assert_equal Pack::CLASS_MAX, Pack.for(pack: 'neutral', classes: 12).categories.sum(&:reward)
  end

  # The numbers the wizard promises for one semester, spelled out so a change to
  # the rounding rule cannot pass silently.
  test 'a twelve-class neutral set scales to the documented numbers' do
    preset = Pack.for(pack: 'neutral', classes: 12)

    assert_equal 132, preset.total_earnable
    assert_equal [0, 20, 40, 65, 100], preset.ranks.map(&:threshold)
    assert_equal [0, 3, 5, 10, 15], preset.ranks.map(&:discount)
    assert_equal [11, 17, 11, 22, 28, 33, 79], preset.items.map(&:price)
  end

  test 'every pack has the same shape and differs only in names' do
    sets = Pack::KEYS.map { |key| Pack.for(pack: key, classes: 12) }

    sets.each do |preset|
      assert_equal 5, preset.ranks.size
      assert_equal 6, preset.badges.size
      assert_equal 7, preset.items.size
      assert_equal 8, preset.categories.size
    end

    assert_equal 1, sets.map { |preset| preset.ranks.map(&:threshold) }
                        .uniq.size
    assert_equal 1, sets.map { |preset| preset.items.map(&:price) }
                        .uniq.size
    assert_equal Pack::KEYS.size, sets.map { |preset| preset.ranks.map(&:name) }
                                      .uniq.size
  end

  # Ranks have a unique index on [story_group_id, required_currency_value], and
  # rounding to 5 can put two rungs on one number at a low class count.
  test 'rank thresholds strictly increase for every offered class count' do
    Pack::KEYS.each do |key|
      Pack::CLASSES_RANGE.each do |count|
        thresholds = Pack.for(pack: key, classes: count).ranks.map(&:threshold)

        assert_equal thresholds.sort.uniq, thresholds,
                     "#{key}/#{count} produced #{thresholds.inspect}"
      end
    end
  end

  test 'prices never fall below the Item floor of 1' do
    Pack::KEYS.each do |key|
      Pack::CLASSES_RANGE.each do |count|
        assert_operator Pack.for(pack: key, classes: count).items.map(&:price).min, :>=, 1
      end
    end
  end

  # art_chosen rejects a record whose glyph is not in its entity's own set, so a
  # typo here would only surface as a failed create halfway through a build.
  test 'every preset glyph is one the entity actually offers' do
    Pack::KEYS.each do |key|
      preset = Pack.for(pack: key, classes: 12)

      assert_empty preset.ranks.map(&:icon_glyph) - Redesign::Glyphs::RANK
      assert_empty preset.badges.map(&:icon_glyph) - Redesign::Glyphs::BADGE
      assert_empty preset.items.map(&:icon_glyph) - Redesign::Glyphs::ITEM
    end
  end

  # The retired stock-photo mascot: a new group should never be handed it.
  test 'no pack uses the rabbit glyph' do
    Pack::KEYS.each do |key|
      assert_not_includes Pack.for(pack: key, classes: 12).badges.map(&:icon_glyph), 'rabbit'
    end
  end

  test 'badges and items carry the descriptions their models require' do
    Pack::KEYS.each do |key|
      preset = Pack.for(pack: key, classes: 12)

      assert(preset.badges.all? { |badge| badge.didactic_description.present? })
      assert(preset.items.all? { |item| item.didactic_description.present? })
      assert(preset.categories.all? { |category| category.didactic_description.present? })
    end
  end

  test 'only the 1up item is buyable at zero lives' do
    items = Pack.for(pack: 'neutral', classes: 12).items

    assert_equal ['1up: odzyskanie życia'], items.select(&:can_buy_at_0_lives).map(&:name)
  end

  test 'an unknown pack or an out-of-range class count falls back instead of raising' do
    preset = Pack.for(pack: 'nonsense', classes: 999)

    assert_equal Pack::KEYS.first, preset.pack
    assert_equal Pack::CLASSES_RANGE.max, preset.classes
    assert_equal Pack::CLASSES_RANGE.min, Pack.for(pack: 'neutral', classes: 1).classes
  end
end
