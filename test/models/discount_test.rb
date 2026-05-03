# frozen_string_literal: true

require 'test_helper'

class DiscountTest < ActiveSupport::TestCase
  test 'capping when discount is greater than 50' do
    discount = Discount.new(65)

    assert_equal 50, discount.value
    assert discount.capped
    assert_equal 65, discount.raw_total
  end

  test 'no capping when discount is 50 or less' do
    discount = Discount.new(30)

    assert_equal 30, discount.value
    refute discount.capped
    assert_equal 30, discount.raw_total
  end
end
