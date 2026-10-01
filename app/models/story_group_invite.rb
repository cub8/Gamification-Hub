# frozen_string_literal: true

class StoryGroupInvite < ApplicationRecord
  include ApplicationHelper

  CODE_LENGTH = 6

  CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'

  STATUS_LABELS = {
    active:    'Aktywne',
    expired:   'Wygasło',
    exhausted: 'Wyczerpane',
  }.freeze

  before_create :generate_code

  belongs_to :story_group

  validates :code, uniqueness: true
  validates :uses, numericality: true

  validates :max_uses,
            numericality: {
              only_integer:             true,
              greater_than_or_equal_to: 1,
              message:                  'Limit musi wynosić co najmniej 1.',
            },
            allow_nil:    true

  validate :max_uses_covers_existing_uses

  class << self
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

  def max_uses_covers_existing_uses
    return if max_uses.blank? || uses.to_i.zero? || max_uses >= uses

    errors.add(
      :max_uses,
      "Z tego kodu skorzystało już #{uses} #{gh_plural(uses, 'osoba', 'osoby', 'osób')}. " \
      'Limit nie może być mniejszy.',
    )
  end
end
