# frozen_string_literal: true

class CurrencyAdjusterService
  class Overdrawn < StandardError; end

  def initialize(student:, granted_by_user:)
    @student         = student
    @granted_by_user = granted_by_user
  end

  def adjust(amount)
    raise Overdrawn if (@student.current_currency.to_i + amount.to_i).negative?

    ActiveRecord::Base.transaction do
      @student.increment!(:current_currency, amount)
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
