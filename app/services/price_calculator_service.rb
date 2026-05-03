# frozen_string_literal: true

class PriceCalculatorService
  def initialize(price:, discount:)
    @price = price
    @discount = discount
  end

  def calculate
    return @price if @discount.value.zero?

    (@price * (100 - @discount.value) / 100.0).ceil
  end
end
