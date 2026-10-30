# frozen_string_literal: true

module Csv
  class PresetParams
    def initialize(setup, story_group:)
      @setup = setup || {}
      @story_group = story_group
    end

    def call
      GroupPreset.new(ranks: ranks, badges: badges, items: items, templates: templates, warnings: warnings)
    end

    private

    attr_reader :story_group

    def warnings = Array(@setup[:warnings])

    def rows_for(zone)
      bucket = @setup[zone]
      return [] if bucket.blank?

      bucket.to_unsafe_h.sort_by { |index, _| index.to_i }
    end

    def ranks
      rows_for(:ranks).map do |index, row|
        RanksImport::Row.new(index: index.to_i, name: row[:name], threshold: row[:threshold],
                             discount: row[:discount], icon_glyph: row[:icon_glyph],)
      end
    end

    def badges
      rows_for(:badges).map do |index, row|
        BadgesImport::Row.new(index:                 index.to_i, name: row[:name],
                              didactic_description:  row[:didactic_description],
                              story_description:     row[:story_description].presence,
                              discount:              row[:discount], icon_glyph: row[:icon_glyph],)
      end
    end

    def items
      rows_for(:items).map do |index, row|
        ItemsImport::Row.new(
          index:                 index.to_i,
          name:                  row[:name],
          price:                 row[:price],
          didactic_description:  row[:didactic_description],
          story_description:     row[:story_description].presence,
          icon_glyph:            row[:icon_glyph],
          can_buy_at_0_lives:    row[:can_buy_at_0_lives] == '1',
          unlock_rank:           resolve_rank(row[:unlock_rank]),
          min_rank_for_discount: resolve_rank(row[:min_rank_for_discount]),
          unlock_badges:         resolve_badges(row[:unlock_badges]),
          discount_badges:       resolve_badges(row[:discount_badges]),
        )
      end
    end

    def templates
      rows_for(:templates).map do |index, template|
        TemplatesImport::Template.new(index: index.to_i, name: template[:name], categories: categories_for(template))
      end
    end

    def categories_for(template)
      bucket = template[:categories]
      return [] if bucket.blank?

      sorted = bucket.sort_by { |index, _| index.to_i }
      sorted.map do |index, category|
        TemplatesImport::Category.new(index: index.to_i, didactic_description: category[:didactic_description],
                                      story_description:    category[:story_description].presence,
                                      reward:               category[:reward],)
      end
    end

    def resolve_rank(value)
      resolve_ref(value) { |id| story_group.ranks.find_by(id: id) }
    end

    def resolve_badges(values)
      Array(values).filter_map { |value| resolve_ref(value) { |id| story_group.badges.kept.find_by(id: id) } }
    end

    def resolve_ref(value)
      return if value.blank?

      tag, raw = value.split(':', 2)

      case tag
      when 'batch' then raw.to_i
      when 'existing' then yield(raw)
      end
    end
  end
end
