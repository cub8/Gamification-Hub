# frozen_string_literal: true

class LoginToken < ApplicationRecord
  belongs_to :user

  before_create :setup_expires_at!

  has_secure_token length: 32
  encrypts :token, deterministic: true

  def expired?
    ::Time.current > expires_at
  end

  def setup_expires_at!
    self.expires_at = 5.minutes.from_now
  end
end
