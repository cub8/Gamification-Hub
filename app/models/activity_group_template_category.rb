# frozen_string_literal: true

# One category of a template — the thing each sheet column is stamped from.
# Templates have no `hidden`: nothing has been awarded against them, so a
# category you no longer want is simply removed.
class ActivityGroupTemplateCategory < ApplicationRecord
  default_scope { order(position: :asc) }

  belongs_to :activity_group_template

  validates :didactic_description, presence: { message: 'Podaj, za co jest nagroda.' }
  validates :reward,
            numericality: {
              only_integer:             true,
              greater_than_or_equal_to: 1,
              message:                  'Nagroda musi wynosić co najmniej 1.',
            }
end
