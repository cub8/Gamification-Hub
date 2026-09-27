# frozen_string_literal: true

class StarterPackBuilder
  class InvalidSelection < StandardError; end

  Result = Data.define(:ranks, :badges, :items, :categories)

  def initialize(story_group:, pack:, classes:, selection: {})
    @story_group = story_group
    @preset      = StarterPack.for(pack: pack, classes: classes)
    @selection   = selection || {}
  end

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

  def create_template
    template = story_group.activity_group_templates.new(base_name: StarterPack::TEMPLATE_NAME)

    kept(:cats, preset.categories).each_with_index do |category, position|
      template.categories.new(didactic_description: category.didactic_description,
                              story_description:    category.story_description,
                              reward:               override(:cats, category.index, category.reward),
                              position:             position,)
    end

    template.save!
    template.categories
  end

  def kept(zone, rows)
    rows.reject { |row| row_for(zone, row.index)&.fetch(:keep, true) == false }
  end

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
