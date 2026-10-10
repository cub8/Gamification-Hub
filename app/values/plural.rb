# frozen_string_literal: true

module Plural
  extend self

  def pick(count, one, few, many)
    n        = count.abs
    last_two = n % 100
    last_one = n % 10

    return one if n == 1
    return few if last_one.between?(2, 4) && !last_two.between?(12, 14)

    many
  end
end
