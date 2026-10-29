# frozen_string_literal: true

module RewardCategory
  extend ActiveSupport::Concern

  included do
    default_scope { order(position: :asc) }

    validates :didactic_description, presence: true
    validates :reward,
              numericality: {
                only_integer:             true,
                greater_than_or_equal_to: 1,
                message:                  :too_low,
              }
  end
end
