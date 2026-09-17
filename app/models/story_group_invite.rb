# frozen_string_literal: true

class StoryGroupInvite < ApplicationRecord
  # gh_plural only, for the two validation messages that count people. Touches
  # no view context, exactly as StoryGroupsListing does.
  include RedesignHelper

  CODE_LENGTH = 6

  # No O, 0, I, 1 or L (DECISIONS.md). A code is read off a projector or a
  # printout and typed into six boxes, so every character has to survive being
  # confused with another one.
  CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'

  # Derived from `uses`/`max_uses`/`expires_at` against "now", never stored.
  # The invites screen groups on it (mockup 30-isg.js:22).
  STATUS_LABELS = {
    active:    'Aktywne',
    expired:   'Wygasło',
    exhausted: 'Wyczerpane',
  }.freeze

  before_create :generate_code

  belongs_to :story_group

  validates :code, uniqueness: true
  validates :uses, numericality: true

  # Both limits are optional, each behind its own switch on the form. Off means
  # NULL — never zero, never a sentinel (30-isg.js:87).
  validates :max_uses,
            numericality: {
              only_integer:             true,
              greater_than_or_equal_to: 1,
              message:                  'Limit musi wynosić co najmniej 1.',
            },
            allow_nil:    true

  validate :max_uses_covers_existing_uses

  # NOTE: "the expiry must be in the future" is NOT here. It is a form-time
  # rule, not a data rule — a code that expired yesterday is a perfectly valid
  # record, and tests and the clock both need to be able to produce one. It
  # lives in InviteForm, which is the only thing that sets the date.

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

  # Expiry wins over exhaustion: a code that is both reads as "Wygasło", which
  # is the remedy the teacher has to act on first.
  def status
    return :expired   unless expire_time_condition
    return :exhausted unless use_count_condition

    :active
  end

  def active? = status == :active

  def status_label = STATUS_LABELS[status]

  def use!
    return unless usable?

    increment!(:uses)
  end

  private

  # DECISIONS.md: "Edit keeps code; limit >= uses." Lowering the limit below the
  # number of people who already joined would retroactively lock them out of a
  # group they are in, so the form refuses instead.
  def max_uses_covers_existing_uses
    return if max_uses.blank? || uses.to_i.zero? || max_uses >= uses

    errors.add(
      :max_uses,
      "Z tego kodu skorzystało już #{uses} #{gh_plural(uses, 'osoba', 'osoby', 'osób')}. " \
      'Limit nie może być mniejszy.',
    )
  end
end
