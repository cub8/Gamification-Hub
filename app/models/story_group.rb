# frozen_string_literal: true

class StoryGroup < ApplicationRecord
  has_one_attached :icon
  has_one_attached :currency_icon
end
