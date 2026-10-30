# frozen_string_literal: true

module Csv
  class BadgesExport
    COLUMN_KEYS = %i[name didactic_description story_description discount icon].freeze

    def initialize(story_group:)
      @story_group = story_group
    end

    def call
      CSV.generate do |csv|
        csv << Localized.column_names('badges', COLUMN_KEYS)
        @story_group.badges.kept.by_name.each { |badge| csv << row_for(badge) }
      end
    end

    private

    def row_for(badge)
      [badge.name, badge.didactic_description, badge.story_description, badge.discount, badge.icon_glyph]
    end
  end
end
