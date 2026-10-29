# frozen_string_literal: true

module Csv
  class TemplatesImport
    Template = Data.define(:index, :name, :categories)
    Category = Data.define(:index, :didactic_description, :story_description, :reward)

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
      @file.rewind
      @file.read.force_encoding(Encoding::UTF_8).delete_prefix(Csv::Utf8Bom)
    end

    def grouped
      rows.group_by { |row| column(row, :number).to_i }
          .sort.to_h
    end

    def template_for(rows, index)
      sorted = rows.sort_by { |row| column(row, :position).to_i }

      Template.new(index: index, name: column(sorted.first, :name), categories: categories_for(sorted))
    end

    def categories_for(rows)
      rows.each_with_index.filter_map { |row, index| category_for(row, index) }
    end

    def category_for(row, index)
      didactic_description = column(row, :didactic_description)
      reward = column(row, :reward)
      return if didactic_description.blank? && reward.blank?

      Category.new(
        index:                index,
        didactic_description: didactic_description,
        story_description:    column(row, :story_description).presence,
        reward:               reward,
      )
    end

    def column(row, key)
      Localized.column(row, "activity_group_templates.csv_columns.#{key}")
    end
  end
end
