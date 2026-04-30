# frozen_string_literal: true

class CurrencyAdjuster
  def initialize(student:, granted_by_user:)
    @student         = student
    @granted_by_user = granted_by_user
  end

  def adjust(amount)
    ActiveRecord::Base.transaction do
      @student.increment!(:current_currency, amount)
      @student.increment!(:total_currency, amount)
      CurrencyTransaction.create!(
        student:         @student,
        amount:          amount,
        granted_by_user: @granted_by_user,
        kind:            :adjustment,
      )
    end
  end
end
