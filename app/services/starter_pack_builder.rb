# frozen_string_literal: true

# Turns a Redesign::StarterPack into real records for a freshly created group.
#
# The wizard's step 4 renders the same pack and lets the teacher drop rows and
# retype numbers before anything exists, so this takes those edits as
# `selection` and never invents them itself. Shape, straight off the form:
#
#   { ranks:  { 0 => { keep: true, value: 20 }, ... },
#     badges: { 0 => { keep: true }, ... },
#     items:  { 0 => { keep: true, value: 11 }, ... },
#     cats:   { 0 => { keep: true, value: 1 },  ... } }
#
# A missing entry means "keep, unedited", so a pack built with no selection at
# all is the untouched preset — which is what the controller passes when the
# teacher walks straight through.
#
# Order matters: items point at ranks and badges through four different
# associations, so both have to exist first. Same reasoning as db/seeds/items.rb.
class StarterPackBuilder
  # Raised when the teacher's own numbers cannot become records — today only
  # two rank thresholds edited onto the same value, which the unique index on
  # [story_group_id, required_currency_value] refuses. Carries the Polish
  # sentence the wizard puts in its error slot.
  class InvalidSelection < StandardError; end

  Result = Struct.new(:ranks, :badges, :items, :categories)

  def initialize(story_group:, pack:, classes:, selection: {})
    @story_group = story_group
    @preset      = Redesign::StarterPack.for(pack: pack, classes: classes)
    @selection   = selection || {}
  end

  # One transaction for everything: a group left with three of its five ranks
  # is worse than a group left empty, and the teacher cannot tell the
  # difference from the outside.
  def call
    ActiveRecord::Base.transaction do
      ranks  = create_ranks
      badges = create_badges

      Result.new(ranks:      ranks.values,
                 badges:     badges.values,
                 items:      create_items(ranks, badges),
                 categories: create_template,)
    end
  end

  private

  attr_reader :story_group, :preset, :selection

  # Kept rows only, indexed by the preset's own index so items can look their
  # requirements up even when the rows around them were dropped.
  def create_ranks
    thresholds = {}

    kept(:ranks, preset.ranks).to_h do |rank|
      value = override(:ranks, rank.index, rank.threshold)
      guard_threshold!(thresholds, value, rank.name)

      [rank.index,
       story_group.ranks.create!(name:                    rank.name,
                                 required_currency_value: value,
                                 discount:                rank.discount,
                                 icon_glyph:              rank.icon_glyph,),]
    end
  end

  def create_badges
    kept(:badges, preset.badges).to_h do |badge|
      [badge.index,
       story_group.badges.create!(name:                 badge.name,
                                  didactic_description: badge.didactic_description,
                                  story_description:    badge.story_description,
                                  discount:             badge.discount,
                                  icon_glyph:           badge.icon_glyph,),]
    end
  end

  # A requirement whose rank or badge the teacher deleted is simply dropped:
  # the item stays buyable rather than pointing at nothing. `compact` on the
  # badge lists does that for the two has_many sides, and `[]` on the hashes
  # for the two belongs_to sides.
  def create_items(ranks, badges)
    kept(:items, preset.items).map do |item|
      story_group.items.create!(
        name:                  item.name,
        price:                 override(:items, item.index, item.price),
        didactic_description:  item.didactic_description,
        story_description:     item.story_description,
        icon_glyph:            item.icon_glyph,
        can_buy_at_0_lives:    item.can_buy_at_0_lives,
        unlock_rank:           ranks[item.unlock_rank],
        min_rank_for_discount: ranks[item.min_rank_for_discount],
        discount_badges:       item.discount_badges.filter_map { |index| badges[index] },
      )
    end
  end

  # One template, not sheets: a sheet is stamped per class afterwards, through
  # ActivityGroupBuilder, and DECISIONS.md:30 makes a template edit affect only
  # sheets created later — so creating them up front would freeze the preset in
  # place before the teacher has read it.
  def create_template
    template = story_group.activity_group_templates.new(base_name: Redesign::StarterPack::TEMPLATE_NAME)

    kept(:cats, preset.categories).each_with_index do |category, position|
      template.categories.new(didactic_description: category.didactic_description,
                              story_description:    category.story_description,
                              reward:               override(:cats, category.index, category.reward),
                              position:             position,)
    end

    template.save!
    template.categories
  end

  # ---- the teacher's edits -------------------------------------------------

  def kept(zone, rows)
    rows.reject { |row| row_for(zone, row.index)&.fetch(:keep, true) == false }
  end

  # Blank means "I cleared the field", which is not a number and must not
  # silently become 0 — the preset's own value stands.
  def override(zone, index, fallback)
    raw = row_for(zone, index)&.dig(:value)
    return fallback if raw.nil? || raw.to_s.strip.empty?

    raw.to_i
  end

  def row_for(zone, index)
    selection.dig(zone, index)
  end

  def guard_threshold!(seen, value, name)
    if seen.key?(value)
      raise InvalidSelection,
            "Dwie rangi nie mogą mieć tego samego progu: #{seen[value]} i #{name} mają #{value}."
    end

    seen[value] = name
  end
end
