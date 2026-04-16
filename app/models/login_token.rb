# frozen_string_literal: true

class LoginToken < ApplicationRecord
  TOKEN_BYTES = 24

  belongs_to :user

  before_create :generate_token!

  # Present only in freshly created objects.
  attr_reader :raw_token

  def expired?
    ::Time.current > expires_at
  end

  class << self
    def digest(token)
      OpenSSL::Digest::SHA256.hexdigest(token)
    end

    def find_by_token(raw_token)
      digest = digest(raw_token)
      find_by(token_digest: digest)
    end
  end

  private

  def generate_token!
    raw_token = SecureRandom.base58(TOKEN_BYTES)

    @raw_token = raw_token
    self.token_digest = self.class.digest(raw_token)
    self.expires_at = 5.minutes.from_now
  end
end
