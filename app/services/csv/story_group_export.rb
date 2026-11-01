# frozen_string_literal: true

module Csv
  class StoryGroupExport
    EXPORTERS = {
      'ranks'     => RanksExport,
      'badges'    => BadgesExport,
      'items'     => ItemsExport,
      'templates' => TemplatesExport,
    }.freeze

    RESOURCES = EXPORTERS.keys.freeze

    class << self
      def supports?(resource) = EXPORTERS.key?(resource.to_s)

      def labels
        RESOURCES.index_with { |resource| I18n.t("story_group_exports.resources.#{resource}") }
      end
    end

    def initialize(story_group:)
      @story_group = story_group
    end

    def csv_for(resource)
      EXPORTERS[resource.to_s].new(story_group: @story_group).call
    end
  end
end
