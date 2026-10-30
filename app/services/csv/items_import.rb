# frozen_string_literal: true

module Csv
  class ItemsImport
    include ParsesRows

    CSV_SCOPE = 'items'

    Row = Data.define(:index, :name, :price, :didactic_description, :story_description, :icon_glyph,
                      :unlock_rank, :min_rank_for_discount, :unlock_badges, :discount_badges,
                      :can_buy_at_0_lives,)

    RANK_LABEL = /\A(.+) \((-?\d+)\)\z/

    attr_reader :warnings

    def initialize(file:, ranks: [], badges: [], story_group: nil)
      @file = file
      @ranks = ranks
      @badges = badges
      @story_group = story_group
      @warnings = []
    end

    def call
      rows.each_with_index.map { |row, index| row_for(row, index) }
    rescue ::CSV::MalformedCSVError
      raise Csv::MalformedFile
    end

    private

    attr_reader :ranks, :badges, :story_group

    def row_for(row, index)
      name = column(row, :name)

      Row.new(
        index:                 index,
        name:                  name,
        price:                 column(row, :price),
        didactic_description:  column(row, :didactic_description),
        story_description:     column(row, :story_description).presence,
        icon_glyph:            icon_glyph(column(row, :icon)),
        can_buy_at_0_lives:    boolean(column(row, :can_buy_at_0_lives)),
        unlock_rank:           resolve_rank(column(row, :unlock_rank), name),
        min_rank_for_discount: resolve_rank(column(row, :min_rank_for_discount), name),
        unlock_badges:         resolve_badges(column(row, :unlock_badges), name),
        discount_badges:       resolve_badges(column(row, :discount_badges), name),
      )
    end

    def boolean(value)
      Localized.aliases('items.csv_values.yes').map(&:downcase).include?(value.to_s.strip.downcase)
    end

    def icon_glyph(value)
      return value if Glyphs::ITEM.include?(value)

      Glyphs::ITEM.first
    end

    def resolve_rank(label, item_name)
      return if label.blank?

      match = RANK_LABEL.match(label.strip)
      unless match
        warnings << I18n.t('items.csv_import.rank_format_unrecognized', label: label, item: item_name)
        return
      end

      name, threshold = match.captures
      in_batch = ranks.find { |r| r.name == name && r.threshold.to_s == threshold }
      return in_batch.index if in_batch

      existing = story_group&.ranks&.find_by(name: name, required_currency_value: threshold)
      return existing if existing

      warnings << I18n.t('items.csv_import.rank_not_found', label: label, item: item_name)
      nil
    end

    def resolve_badges(names, item_name)
      names.to_s.split(';').map(&:strip).reject(&:empty?).filter_map { |name| resolve_badge(name, item_name) }
    end

    def resolve_badge(name, item_name)
      in_batch = badges.find { |b| b.name == name }
      return in_batch.index if in_batch

      existing = story_group && story_group.badges.kept.find_by(name: name)
      return existing if existing

      warnings << I18n.t('items.csv_import.badge_not_found', name: name, item: item_name)
      nil
    end
  end
end
