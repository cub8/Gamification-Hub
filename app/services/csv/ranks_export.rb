# frozen_string_literal: true

module Csv
  class RanksExport
    HEADERS = %w[nazwa próg_waluty zniżka ikona].freeze

    def initialize(story_group:)
      @story_group = story_group
    end

    def call
      CSV.generate do |csv|
        csv << HEADERS
        @story_group.ranks.by_threshold.each { |rank| csv << row_for(rank) }
      end
    end

    private

    def row_for(rank) = [rank.name, rank.required_currency_value, rank.discount, rank.icon_glyph]
  end
end
