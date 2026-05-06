# frozen_string_literal: true

class StoryGroupInvite < ApplicationRecord
  before_create :generate_code

  belongs_to :story_group

  validates :code, uniqueness: true
  validates :uses, numericality: { less_than_or_equal_to: :max_uses }

  def generate_code
    self.code ||= SecureRandom.urlsafe_base64(8)
  end

  def usable?
    uses < max_uses && Time.current < expires_at
  end

  def use!
    return unless usable?

    increment!(:uses)

  end
end
