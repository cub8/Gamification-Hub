# frozen_string_literal: true

# The Polish plural rule, in one place.
#
# It lived only in ApplicationHelper#gh_plural, which is fine while every
# sentence is written in a view. Services that build a sentence themselves —
# TeacherOverview's "9 kolumn bez ocen" — need the same rule, and a helper is
# not reachable from one without going through ApplicationController.helpers.
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
