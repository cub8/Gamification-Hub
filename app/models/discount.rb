# frozen_string_literal: true

class Discount
  CAP_VALUE = 50

  attr_reader :value, :capped, :raw_total

  def initialize(total_value)
    @raw_total = total_value
    @capped = total_value > CAP_VALUE
    @value = [CAP_VALUE, total_value].min
  end
end
