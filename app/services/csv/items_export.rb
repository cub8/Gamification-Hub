# frozen_string_literal: true

module Csv
  class ItemsExport
    COLUMN_KEYS = %i[
      name
      didactic_description
      story_description
      price
      can_buy_at_0_lives
      icon
      unlock_rank
      min_rank_for_discount
      unlock_badges
      discount_badges
    ].freeze

    def initialize(story_group:)
      @story_group = story_group
    end

    def call
      CSV.generate do |csv|
        csv << COLUMN_KEYS.map { |key| Localized.current("items.csv_columns.#{key}") }
        items.each { |item| csv << row_for(item) }
      end
    end

    private

    def items
      @story_group.items.kept.by_price
                  .includes(:unlock_rank, :min_rank_for_discount, :unlock_badges, :discount_badges)
    end

    def row_for(item)
      [
        item.name,
        item.didactic_description,
        item.story_description,
        item.price,
        boolean_label(item.can_buy_at_0_lives),
        item.icon_glyph,
        rank_label(item.unlock_rank),
        rank_label(item.min_rank_for_discount),
        badge_labels(item.unlock_badges),
        badge_labels(item.discount_badges),
      ]
    end

    def boolean_label(value) = Localized.current("items.csv_values.#{value ? 'yes' : 'no'}")

    def rank_label(rank) = rank && "#{rank.name} (#{rank.required_currency_value})"

    def badge_labels(badges) = badges.presence&.map(&:name)&.join(';')
  end
end
