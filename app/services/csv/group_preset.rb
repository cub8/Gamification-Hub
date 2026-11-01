# frozen_string_literal: true

module Csv
  GroupPreset = Data.define(:ranks, :badges, :items, :templates, :warnings) do
    def initialize(ranks: [], badges: [], items: [], templates: [], warnings: [])
      super
    end

    def any? = ranks.any? || badges.any? || items.any? || templates.any?
    def none? = !any?
  end
end
