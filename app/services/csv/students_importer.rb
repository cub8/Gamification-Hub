# frozen_string_literal: true

module Csv
  class StudentsImporter
    Result = Data.define(:added, :failures) do
      def initialize(added: [], failures: [])
        super
      end
    end

    Failure = Data.define(:row, :message)

    def initialize(story_group:, file:)
      @story_group = story_group
      @file = file
    end

    def call
      added = []
      failures = []

      StudentsImport.new(file: @file).call.each do |row|
        outcome = add(row)

        if outcome.is_a?(Failure)
          failures << outcome
        else
          added << outcome
        end
      end

      Result.new(added: added, failures: failures)
    end

    private

    def add(row)
      user = User.find_by(email: row.email)
      return no_account(row) unless user

      membership = @story_group.student_memberships.build(user: user, nickname: row.nickname)
      return membership if membership.save

      Failure.new(row: row.index + 2, message: membership.errors.full_messages.to_sentence)
    end

    def no_account(row)
      Failure.new(row: row.index + 2, message: "Nie znaleziono konta dla „#{row.email}”.")
    end
  end
end
