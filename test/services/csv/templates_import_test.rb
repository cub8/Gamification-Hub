# frozen_string_literal: true

require 'test_helper'

module Csv
  class TemplatesImportTest < ActiveSupport::TestCase
    test 'groups rows by nr_szablonu into separate templates, ordered by pozycja' do
      file = StringIO.new(<<~CSV)
        nr_szablonu,szablon,pozycja,opis_dydaktyczny,opis_fabularny,nagroda
        1,Laboratoria,1,Zadanie,,10
        1,Laboratoria,0,Obecność,,5
        2,Wykłady,0,Quiz,,3
      CSV

      templates = TemplatesImport.new(file: file).call

      assert_equal 2, templates.size

      first = templates[0]
      assert_equal 'Laboratoria', first.name
      assert_equal %w[Obecność Zadanie], first.categories.map(&:didactic_description)

      second = templates[1]
      assert_equal 'Wykłady', second.name
      assert_equal ['Quiz'], second.categories.map(&:didactic_description)
    end

    test 'a template with a single blank category row parses as zero categories' do
      file = StringIO.new(<<~CSV)
        nr_szablonu,szablon,pozycja,opis_dydaktyczny,opis_fabularny,nagroda
        1,Pusty,,,,
      CSV

      template = TemplatesImport.new(file: file).call.first

      assert_equal 'Pusty', template.name
      assert_empty template.categories
    end

    test 'raises Csv::MalformedFile for content that is not valid CSV' do
      file = StringIO.new(%("unterminated quote,next))

      assert_raises(Csv::MalformedFile) { TemplatesImport.new(file: file).call }
    end
  end
end
