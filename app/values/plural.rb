# frozen_string_literal: true

module Plural
  extend self

  # 1 -> one, 2-4 -> few, otherwise many, with the usual 12-14 exception
  # (12 minut, not 12 minuty). Mirrors the mockup's pl() (00-shared.js:4).
  def pick(count, one, few, many)
    n        = count.abs
    last_two = n % 100
    last_one = n % 10

    return one if n == 1
    return few if last_one.between?(2, 4) && !last_two.between?(12, 14)

    many
  end
end
