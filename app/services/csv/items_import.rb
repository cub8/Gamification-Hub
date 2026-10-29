# frozen_string_literal: true

module Csv
  class ItemsImport
    Row = Data.define(:index, :name, :price, :didactic_description, :story_description, :icon_glyph,
                      :unlock_rank, :min_rank_for_discount, :unlock_badges, :discount_badges,
                      :can_buy_at_0_lives,)

    HEADERS = %w[
      nazwa
      opis_dydaktyczny
      opis_fabularny
      cena
      można_kupić_przy_0_życiach
      ikona
      ranga_odblokowująca
      ranga_minimalna_dla_zniżki
      odznaki_odblokowujące
      odznaki_dla_zniżki
    ].freeze

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

    def rows
      CSV.parse(content, headers: true)
    end

    def content
      @file.rewind
      @file.read.force_encoding(Encoding::UTF_8).delete_prefix(Csv::Utf8Bom)
    end

    def row_for(row, index)
      Row.new(
        index:                 index,
        name:                  row['nazwa'],
        price:                 row['cena'],
        didactic_description:  row['opis_dydaktyczny'],
        story_description:     row['opis_fabularny'].presence,
        icon_glyph:            icon_glyph(row['ikona']),
        can_buy_at_0_lives:    boolean(row['można_kupić_przy_0_życiach']),
        unlock_rank:           resolve_rank(row['ranga_odblokowująca'], row['nazwa']),
        min_rank_for_discount: resolve_rank(row['ranga_minimalna_dla_zniżki'], row['nazwa']),
        unlock_badges:         resolve_badges(row['odznaki_odblokowujące'], row['nazwa']),
        discount_badges:       resolve_badges(row['odznaki_dla_zniżki'], row['nazwa']),
      )
    end

    def boolean(value) = value.to_s.strip.downcase == 'tak'

    def icon_glyph(value)
      return value if Glyphs::ITEM.include?(value)

      Glyphs::ITEM.first
    end

    def resolve_rank(label, item_name)
      return if label.blank?

      match = RANK_LABEL.match(label.strip)
      unless match
        warnings << "Nie rozpoznano formatu rangi „#{label}” dla przedmiotu „#{item_name}” - pominięto to ograniczenie."
        return
      end

      name, threshold = match.captures
      in_batch = ranks.find { |r| r.name == name && r.threshold.to_s == threshold }
      return in_batch.index if in_batch

      existing = story_group&.ranks&.find_by(name: name, required_currency_value: threshold)
      return existing if existing

      warnings << "Nie znaleziono rangi „#{label}” dla przedmiotu „#{item_name}” - pominięto to ograniczenie."
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

      warnings << "Nie znaleziono odznaki „#{name}” dla przedmiotu „#{item_name}” - pominięto to ograniczenie."
      nil
    end
  end
end
