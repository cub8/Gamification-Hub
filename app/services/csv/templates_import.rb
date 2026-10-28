# frozen_string_literal: true

module Csv
  class TemplatesImport
    Template = Data.define(:index, :name, :categories)
    Category = Data.define(:index, :didactic_description, :story_description, :reward)

    HEADERS = %w[nr_szablonu szablon pozycja opis_dydaktyczny opis_fabularny nagroda].freeze

    def initialize(file:)
      @file = file
    end

    def call
      grouped.each_with_index.map { |(_number, rows), index| template_for(rows, index) }
    rescue ::CSV::MalformedCSVError
      raise Csv::MalformedFile
    end

    private

    def rows
      CSV.parse(content, headers: true)
    end

    def content
      @file.read.force_encoding(Encoding::UTF_8).delete_prefix(Csv::Utf8Bom)
    end

    def grouped
      rows.group_by { |row| row['nr_szablonu'].to_i }
          .sort.to_h
    end

    def template_for(rows, index)
      sorted = rows.sort_by { |row| row['pozycja'].to_i }

      Template.new(index: index, name: sorted.first['szablon'], categories: categories_for(sorted))
    end

    def categories_for(rows)
      rows.each_with_index.filter_map { |row, index| category_for(row, index) }
    end

    def category_for(row, index)
      return if row['opis_dydaktyczny'].blank? && row['nagroda'].blank?

      Category.new(
        index:                index,
        didactic_description: row['opis_dydaktyczny'],
        story_description:    row['opis_fabularny'].presence,
        reward:               row['nagroda'],
      )
    end
  end
end
