# frozen_string_literal: true

module Csv
  class RanksExport
    COLUMN_KEYS = %i[name threshold discount icon].freeze

    def initialize(story_group:)
      @story_group = story_group
    end

    def call
      CSV.generate do |csv|
        csv << COLUMN_KEYS.map { |key| Localized.current("ranks.csv_columns.#{key}") }
        @story_group.ranks.by_threshold.each { |rank| csv << row_for(rank) }
      end
    end

    private

    def row_for(rank) = [rank.name, rank.required_currency_value, rank.discount, rank.icon_glyph]
  end
end
