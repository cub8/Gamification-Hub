# frozen_string_literal: true

# The quick-start set. Numbers and icons live here; every name and description
# comes from story_groups.starter_pack in config/locales/views/story_groups.*.yml,
# in the language of whoever creates the group — the builder writes them to the
# database as plain text, so a group keeps the language it was created in.
class StarterPack
  I18N_SCOPE = 'story_groups.starter_pack'

  CLASS_MAX = 11

  KEYS = %w[neutral fantasy scifi].freeze

  CLASSES_RANGE   = (4..30)
  DEFAULT_CLASSES = 12

  Rank     = Data.define(:index, :name, :threshold, :discount, :icon_glyph)
  Badge    = Data.define(:index, :name, :didactic_description, :story_description, :discount,
                         :icon_glyph,)
  Item     = Data.define(:index, :name, :price, :didactic_description, :story_description, :icon_glyph,
                         :unlock_rank, :min_rank_for_discount, :discount_badges, :can_buy_at_0_lives,)
  Category = Data.define(:index, :didactic_description, :story_description, :reward)

  # Reward per category, in the order of starter_pack.categories.
  CATEGORY_REWARDS = [1, 1, 1, 2, 2, 1, 2, 1].freeze

  RANK_FRACTIONS = [0.0, 0.15, 0.30, 0.50, 0.75].freeze
  RANK_DISCOUNTS = [0, 3, 5, 10, 15].freeze

  BADGE_DISCOUNTS = [2, 5, 5, 3, 5, 7].freeze

  # In the order of starter_pack.items.
  ITEMS = [
    { x: 1.0,  glyph: 'clock',     unlock: nil, discount_rank: 2, discount_badges: [] },
    { x: 1.5,  glyph: 'chat',      unlock: nil, discount_rank: 2, discount_badges: [] },
    { x: 1.0,  glyph: 'retake',    unlock: 1,   discount_rank: 3, discount_badges: [] },
    { x: 2.0,  glyph: 'shield',    unlock: 2,   discount_rank: 3, discount_badges: [1, 3] },
    { x: 2.5,  glyph: 'note',      unlock: 2,   discount_rank: 3, discount_badges: [] },
    { m: 0.25, glyph: 'heartPlus', unlock: nil, discount_rank: 4, discount_badges: [3, 5, 2], at_zero_lives: true },
    { m: 0.60, glyph: 'percent',   unlock: 3,   discount_rank: 4, discount_badges: [5, 1] },
  ].freeze

  RANK_GLYPHS = {
    'neutral' => %w[chev1 chev2 shield starPlus crown],
    'fantasy' => %w[chev1 chev2 shield crown carrotStar],
    'scifi'   => %w[chev1 chev2 rocket compass crown],
  }.freeze

  BADGE_GLYPHS = {
    'neutral' => %w[starPlus shield heartPlus bolt starTrail crew],
    'fantasy' => %w[starPlus shield heartPlus bolt starTrail crown],
    'scifi'   => %w[starPlus rocket wrench compass starTrail crew],
  }.freeze

  class << self
    def include?(key) = KEYS.include?(key.to_s)

    def label_for(key) = text("packs.#{key}.label", default: key.to_s)

    def description_for(key) = text("packs.#{key}.description", default: '')

    def rank_names(key) = list("packs.#{key}.ranks")

    def template_name = text('template_name')

    def category_names = text('categories')

    def for(pack:, classes:)
      new(pack:    include?(pack) ? pack.to_s : KEYS.first,
          classes: classes.to_i.clamp(CLASSES_RANGE.min, CLASSES_RANGE.max),)
    end

    def text(key, **) = I18n.t("#{I18N_SCOPE}.#{key}", **)

    # An array key, or [] when absent. Not `default: []` — I18n reads an Array
    # default as fallback keys, and an empty list of them is still missing.
    def list(key) = I18n.exists?("#{I18N_SCOPE}.#{key}") ? text(key) : []
  end

  def initialize(pack:, classes:)
    @pack    = pack
    @classes = classes
  end

  attr_reader :pack, :classes

  def label       = self.class.label_for(pack)
  def description = self.class.description_for(pack)

  def total_earnable = classes * CLASS_MAX

  def ranks
    @ranks ||= begin
      names  = self.class.rank_names(pack)
      glyphs = RANK_GLYPHS[pack]

      thresholds = RANK_FRACTIONS.each_with_object([]) do |fraction, kept|
        value = round_to_five(fraction * total_earnable)
        kept << (kept.empty? ? value : [value, kept.last + 1].max)
      end

      names.each_with_index.map do |name, index|
        Rank.new(index: index, name: name, threshold: thresholds[index],
                 discount: RANK_DISCOUNTS[index], icon_glyph: glyphs[index],)
      end
    end
  end

  def badges
    @badges ||= begin
      names   = pack_text(:badges)
      rules   = self.class.text('badge_rules')
      glyphs  = BADGE_GLYPHS[pack]
      stories = pack_text(:badge_stories)

      names.each_with_index.map do |name, index|
        Badge.new(index: index, name: name,
                  didactic_description: rules[index],
                  story_description: stories[index],
                  discount: BADGE_DISCOUNTS[index], icon_glyph: glyphs[index],)
      end
    end
  end

  def items
    @items ||= begin
      texts   = self.class.text('items')
      stories = pack_text(:item_stories)

      ITEMS.each_with_index.map do |spec, index|
        Item.new(index: index, name: texts[index][:name], price: price_for(spec),
                 didactic_description: texts[index][:didactic],
                 story_description: stories[index],
                 icon_glyph: spec[:glyph],
                 unlock_rank: spec[:unlock],
                 min_rank_for_discount: spec[:discount_rank],
                 discount_badges: spec[:discount_badges],
                 can_buy_at_0_lives: spec.fetch(:at_zero_lives, false),)
      end
    end
  end

  def categories
    @categories ||= begin
      stories = pack_text(:category_stories)

      self.class.category_names.each_with_index.map do |label, index|
        Category.new(index: index, didactic_description: label,
                     story_description: stories[index], reward: CATEGORY_REWARDS[index],)
      end
    end
  end

  private

  # A pack without story lines (neutral) simply has no such key.
  def pack_text(key) = self.class.list("packs.#{pack}.#{key}")

  def price_for(spec)
    raw = spec[:x] ? spec[:x] * CLASS_MAX : spec[:m] * total_earnable

    [raw.round, 1].max
  end

  def round_to_five(value) = (value / 5.0).round * 5
end
