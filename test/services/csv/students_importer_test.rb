# frozen_string_literal: true

require 'test_helper'

module Csv
  class StudentsImporterTest < ActiveSupport::TestCase
    setup do
      @story_group = FactoryBot.create(:story_group)
    end

    test 'adds a student found by email, with the given nickname' do
      user = FactoryBot.create(:user, role: :student, email: 'jan@example.com')
      file = StringIO.new(<<~CSV)
        email,pseudonim
        jan@example.com,Kapitan
      CSV

      result = StudentsImporter.new(story_group: @story_group, file: file).call

      assert_equal 1, result.added.size
      assert_empty result.failures
      assert_equal user, result.added.first.user
      assert_equal 'Kapitan', result.added.first.nickname
    end

    test 'reports a failure for an email with no matching account, and still imports the rest' do
      FactoryBot.create(:user, role: :student, email: 'jan@example.com')
      file = StringIO.new(<<~CSV)
        email,pseudonim
        nieznany@example.com,
        jan@example.com,
      CSV

      result = StudentsImporter.new(story_group: @story_group, file: file).call

      assert_equal 1, result.added.size
      assert_equal 1, result.failures.size
      assert_match(/nie znaleziono konta/i, result.failures.first.message)
      assert_equal 2, result.failures.first.row
    end

    test 'reports a failure when the user is already a member of the group' do
      user = FactoryBot.create(:user, role: :student, email: 'jan@example.com')
      FactoryBot.create(:story_group_student, story_group: @story_group, user: user)
      file = StringIO.new(<<~CSV)
        email,pseudonim
        jan@example.com,
      CSV

      result = StudentsImporter.new(story_group: @story_group, file: file).call

      assert_empty result.added
      assert_equal 1, result.failures.size
    end

    test 'raises Csv::MalformedFile for content that is not valid CSV' do
      file = StringIO.new(%("unterminated quote,next))

      assert_raises(Csv::MalformedFile) { StudentsImporter.new(story_group: @story_group, file: file).call }
    end
  end
end
