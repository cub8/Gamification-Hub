class Item < ApplicationRecord
  belongs_to :story_group

  validates :name, presence: true
end