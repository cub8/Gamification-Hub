# frozen_string_literal: true

class StoryGroupInvite < ApplicationRecord
  before_create :generate_code

  belongs_to :story_group

  validates :code, uniqueness: true
  validates :max_uses, numericality: { greater_than_or_equal_to: :uses }

  def generate_code
    self.code ||= SecureRandom.urlsafe_base64(8)
  end

  def use
    uses += 1

    update(uses: uses)
  end
end
