# frozen_string_literal: true

class Organization < ApplicationRecord

  has_many :users, dependent: :destroy

  validates :name, length: { maximum: 100 }

  def join_condition
    users.size < max_members
  end

end
