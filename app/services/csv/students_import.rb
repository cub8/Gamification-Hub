# frozen_string_literal: true

module Csv
  class StudentsImport
    include ParsesRows

    CSV_SCOPE = 'students'

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

    def row_for(row, index)
      Row.new(index: index, email: column(row, :email), nickname: column(row, :nickname).presence)
    end
  end
end
