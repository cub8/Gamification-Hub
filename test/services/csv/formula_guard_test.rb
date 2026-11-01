# frozen_string_literal: true

require 'test_helper'

module Csv
  class FormulaGuardTest < ActiveSupport::TestCase
    PAYLOADS = ['=HYPERLINK("http://evil","x")', '+1+1', '-2+3', '@SUM(1)', "\t=1+1", "\r=1+1"].freeze

    test 'escape prefixes text that a spreadsheet would run as a formula' do
      PAYLOADS.each { |payload| assert_equal "'#{payload}", FormulaGuard.escape(payload) }
    end

    test 'escape leaves ordinary text, numbers and nil alone' do
      ['Zuch', "O'Neil", '', 'a=b'].each { |value| assert_equal value, FormulaGuard.escape(value) }
      assert_equal 5, FormulaGuard.escape(5)
      assert_equal(-5, FormulaGuard.escape(-5))
      assert_nil FormulaGuard.escape(nil)
    end

    test 'unescape reverses escape' do
      PAYLOADS.each { |payload| assert_equal payload, FormulaGuard.unescape(FormulaGuard.escape(payload)) }
    end

    test 'unescape leaves a leading apostrophe alone when it was not added by escape' do
      assert_equal "'Zuch", FormulaGuard.unescape("'Zuch")
      assert_equal "'", FormulaGuard.unescape("'")
      assert_nil FormulaGuard.unescape(nil)
    end

    test 'badge names survive an export and re-import unchanged and are never exported as live formulas' do
      story_group = FactoryBot.create(:story_group)
      FactoryBot.create(:badge, story_group: story_group, name: '=1+1', didactic_description: '@x')

      csv = BadgesExport.new(story_group: story_group).call
      exported = CSV.parse(csv, headers: true).first

      assert_equal "'=1+1", exported['nazwa']
      assert_equal "'@x", exported['opis_dydaktyczny']

      imported = BadgesImport.new(file: StringIO.new(csv)).call.first
      assert_equal '=1+1', imported.name
      assert_equal '@x', imported.didactic_description
    end
  end
end
