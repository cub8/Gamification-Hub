# frozen_string_literal: true

class Organization < ApplicationRecord

  has_many :users, foreign_key: 'university_id', dependent: :destroy

  validates :name, length: { maximum: 100 }

  def join_condition
    users.size < max_members
  end

end
