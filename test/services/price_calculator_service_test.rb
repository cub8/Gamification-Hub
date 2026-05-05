# frozen_string_literal: true

require 'test_helper'

class PriceCalculatorServiceTest < ActiveSupport::TestCase
  test 'returns full price when discount is 0' do
    discount = Discount.new(0)
    service = PriceCalculatorService.new(price: 100, discount: discount)

    assert_equal 100, service.calculate
  end

  test 'applies discount correctly' do
    discount = Discount.new(50)
    service = PriceCalculatorService.new(price: 100, discount: discount)

    assert_equal 50, service.calculate
  end

  test 'rounds up the final price using ceil' do
    discount = Discount.new(16)
    service = PriceCalculatorService.new(price: 30, discount: discount)
    # 30 * 0.84 = 25.2, .ceil powinno dać 26.
    assert_equal 26, service.calculate
  end
end
