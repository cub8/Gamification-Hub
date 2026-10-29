# frozen_string_literal: true

module Csv
  class StudentsImport
    Row = Data.define(:index, :email, :nickname)

    def initialize(file:)
      @file = file
    end

    def call
      rows.each_with_index.map { |row, index| row_for(row, index) }
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

    def row_for(row, index)
      Row.new(index: index, email: column(row, :email), nickname: column(row, :nickname).presence)
    end

    def column(row, key)
      Localized.column(row, "students.csv_columns.#{key}")
    end
  end
end
