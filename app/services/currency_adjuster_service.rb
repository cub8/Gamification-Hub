# frozen_string_literal: true

class CurrencyAdjusterService
  # A correction that would take the spendable balance below zero is refused
  # rather than clamped: the caller asked for a specific number, and silently
  # taking less would tell the teacher something happened that did not.
  # CurrencyAdjustmentForm catches this first and puts the message on the field;
  # this is the floor under any other caller (DECISIONS.md:32).
  class Overdrawn < StandardError; end

  def initialize(student:, granted_by_user:)
    @student         = student
    @granted_by_user = granted_by_user
  end

  def adjust(amount)
    raise Overdrawn if (@student.current_currency.to_i + amount.to_i).negative?

    ActiveRecord::Base.transaction do
      @student.increment!(:current_currency, amount)
      # Only a positive correction raises the total collected, so a clawback
      # can never cost a student a rank they already reached (DECISIONS.md:32).
      @student.increment!(:total_currency, amount) if amount.positive?
      CurrencyTransaction.create!(
        student:         @student,
        amount:          amount,
        granted_by_user: @granted_by_user,
        kind:            :adjustment,
      )
    end
  end
end
