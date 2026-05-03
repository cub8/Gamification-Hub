# frozen_string_literal: true

class DiscountCalculatorService
  def initialize(student:, item:)
    @student = student
    @item = item
  end

  def calculate
    return Discount.new(0) unless eligible_for_discount?

    total_discount = discount_from_rank + discount_from_badges
    Discount.new(total_discount)
  end

  private

  def eligible_for_discount?
    requires_rank = @item.min_rank_for_discount.present?
    requires_badges = @item.discount_badges.any?

    meets_rank = requires_rank && @student.rank.present? && @student.total_currency >=
                                                            @item.min_rank_for_discount.required_currency_value
    meets_badges = requires_badges && student_badges.intersect?(@item.discount_badges)

    return true if !requires_rank && !requires_badges
    return meets_rank || meets_badges if requires_rank && requires_badges
    return meets_rank if requires_rank

    meets_badges
  end

  def discount_from_rank
    @student.rank&.discount || 0
  end

  def discount_from_badges
    student_badges.sum { |b| b.discount || 0 }
  end

  def student_badges
    @student_badges ||= @student.students_badges.includes(:badge).map(&:badge)
  end
end
