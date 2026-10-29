# frozen_string_literal: true

module Csv
  class TemplatesExport
    HEADERS = %w[nr_szablonu szablon pozycja opis_dydaktyczny opis_fabularny nagroda].freeze

    def initialize(story_group:)
      @story_group = story_group
    end

    def call
      CSV.generate do |csv|
        csv << HEADERS
        templates.each_with_index { |template, index| append_template(csv, template, index + 1) }
      end
    end

    private

    def templates
      @story_group.activity_group_templates.kept.order(:id).includes(:categories)
    end

    def append_template(csv, template, number)
      if template.categories.empty?
        csv << [number, template.base_name, nil, nil, nil, nil]
      else
        template.categories.sort_by(&:position).each { |category| csv << row_for(template, number, category) }
      end
    end

    def row_for(template, number, category)
      [
        number,
        template.base_name,
        category.position,
        category.didactic_description,
        category.story_description,
        category.reward,
      ]
    end
  end
end
