# frozen_string_literal: true

class StoryGroupInvite < ApplicationRecord
  before_create :generate_code

  belongs_to :story_group

  validates :code, uniqueness: true
  validates :uses, numericality: true

  def generate_code
    self.code ||= SecureRandom.urlsafe_base64(8)
  end

  def use_count_condition
    max_uses.nil? || uses < max_uses
  end

  def expire_time_condition
    expires_at.nil? || Time.current < expires_at
  end

  def usable?
    use_count_condition && expire_time_condition
  end

  def use!
    return unless usable?

    increment!(:uses)

  end
end
