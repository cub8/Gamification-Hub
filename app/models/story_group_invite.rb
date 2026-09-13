# frozen_string_literal: true

class StoryGroupInvite < ApplicationRecord
  CODE_LENGTH = 6

  # No O, 0, I, 1 or L (DECISIONS.md). A code is read off a projector or a
  # printout and typed into six boxes, so every character has to survive being
  # confused with another one.
  CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'

  before_create :generate_code

  belongs_to :story_group

  validates :code, uniqueness: true
  validates :uses, numericality: true

  class << self
    # Codes issued before the six-character rule are 11-character
    # urlsafe_base64 and mixed case. They stay valid, so a lookup tries the raw
    # code first and only then the upcased one the join dialog produces.
    def find_by_code(raw)
      code = raw.to_s.strip
      return if code.empty?

      find_by(code: code) || find_by(code: code.upcase)
    end

    def random_code
      characters = Array.new(CODE_LENGTH) { CODE_ALPHABET.chars.sample }

      characters.join
    end
  end

  def generate_code
    self.code ||= loop do
      candidate = StoryGroupInvite.random_code
      break candidate unless StoryGroupInvite.exists?(code: candidate)
    end
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
