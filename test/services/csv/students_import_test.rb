# frozen_string_literal: true

require 'test_helper'

module Csv
  class StudentsImportTest < ActiveSupport::TestCase
    test 'parses email and optional nickname, indexed from zero' do
      file = StringIO.new(<<~CSV)
        email,pseudonim
        jan@example.com,Kapitan
        anna@example.com,
      CSV

      rows = StudentsImport.new(file: file).call

      assert_equal 2, rows.size
      assert_equal StudentsImport::Row.new(index: 0, email: 'jan@example.com', nickname: 'Kapitan'), rows[0]
      assert_equal StudentsImport::Row.new(index: 1, email: 'anna@example.com', nickname: nil), rows[1]
    end

    test 'raises Csv::MalformedFile for content that is not valid CSV' do
      file = StringIO.new(%("unterminated quote,next))

      assert_raises(Csv::MalformedFile) { StudentsImport.new(file: file).call }
    end
  end
end
