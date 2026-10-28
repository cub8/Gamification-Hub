# frozen_string_literal: true

module Csv
  class StudentsImport
    Row = Data.define(:index, :email, :nickname)

    HEADERS = %w[email pseudonim].freeze

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
      @file.read.force_encoding(Encoding::UTF_8).delete_prefix(Csv::Utf8Bom)
    end

    def row_for(row, index)
      Row.new(index: index, email: row['email'], nickname: row['pseudonim'].presence)
    end
  end
end
