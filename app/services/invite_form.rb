# frozen_string_literal: true

# The "Nowe zaproszenie" / "Edytuj zaproszenie" dialog (mockup 30-isg.js:33-41).
#
# The dialog's shape and the record's do not match. The record has two nullable
# columns; the dialog has two switches, a number, and a date split from a time.
# And when a save fails the switches have to come back the way the teacher left
# them, which a bare StoryGroupInvite cannot remember. Hence a form object.
#
# It acts on data rather than merely describing it, so it lives in services.
class InviteForm
  include RedesignHelper # gh_plural, for the summary sentence

  PERMITTED = %i[limit_enabled max_uses expiry_enabled expires_on expires_time].freeze

  # Pre-seeded but hidden (30-isg.js:78), so flipping a switch on never reveals
  # an empty field.
  DEFAULT_MAX_USES = 30
  DEFAULT_TIME     = '23:59'

  attr_reader :invite, :max_uses, :expires_on, :expires_time

  class << self
    # The form as the record currently stands: both switches reflect whether
    # the matching column is set.
    def for(invite)
      expires_at = invite.expires_at

      new(
        invite:         invite,
        limit_enabled:  invite.max_uses.present?,
        max_uses:       invite.max_uses || DEFAULT_MAX_USES,
        expiry_enabled: expires_at.present?,
        expires_on:     (expires_at || Time.zone.now).to_date.to_fs(:iso8601),
        expires_time:   expires_at ? expires_at.strftime('%H:%M') : DEFAULT_TIME,
      )
    end

    def from_params(invite, params)
      attributes = params.fetch(:story_group_invite, {}).permit(*PERMITTED)

      new(
        invite:         invite,
        limit_enabled:  attributes[:limit_enabled] == '1',
        max_uses:       attributes[:max_uses].presence,
        expiry_enabled: attributes[:expiry_enabled] == '1',
        expires_on:     attributes[:expires_on].presence || Time.zone.today.to_fs(:iso8601),
        expires_time:   attributes[:expires_time].presence || DEFAULT_TIME,
      )
    end
  end

  def initialize(invite:, limit_enabled:, max_uses:, expiry_enabled:, expires_on:, expires_time:)
    @invite         = invite
    @limit_enabled  = limit_enabled
    @max_uses       = max_uses
    @expiry_enabled = expiry_enabled
    @expires_on     = expires_on
    @expires_time   = expires_time
  end

  def limit_enabled? = @limit_enabled
  def expiry_enabled? = @expiry_enabled
  def persisted? = invite.persisted?

  # A switch that is off writes NULL — not zero, not a sentinel (30-isg.js:87).
  def save
    invite.max_uses   = limit_enabled? ? max_uses : nil
    invite.expires_at = expiry_enabled? ? combined_expiry : nil

    # The record's own rules run FIRST. Adding the form's error before that and
    # then calling save would have hidden every model error behind it, since a
    # save that never runs never validates. Both sets are wanted at once: a
    # teacher who got the limit and the date wrong should be told both.
    invite.validate
    reject_past_expiry

    invite.errors.empty? && invite.save
  end

  def error_for(attribute) = invite.errors[attribute].first

  # The live sentence under the switches (30-isg.js:32). Rendered here first so
  # it is right before Stimulus boots; invite_form_controller reproduces it.
  def summary
    "Kod będzie działał #{limit_phrase} #{expiry_phrase}."
  end

  # The unit beside the number field. Nominative here, genitive in the sentence
  # above — Polish declines the two differently and the mockup gets it right.
  def unit_label = gh_plural(max_uses.to_i, 'osoba', 'osoby', 'osób')

  private

  def limit_phrase
    return 'bez limitu osób' unless limit_enabled?

    count = max_uses.to_i

    "dla #{count} #{gh_plural(count, 'osoby', 'osób', 'osób')}"
  end

  def expiry_phrase
    return 'i bez daty ważności' unless expiry_enabled?

    "do #{gh_stamp(combined_expiry)}"
  end

  # The mockup builds a naive local string, `M.date + 'T' + M.time`, and never
  # says which zone that is. The app has one, so parse in it.
  def combined_expiry
    @combined_expiry ||= Time.zone.parse("#{expires_on} #{expires_time}")
  end

  # Form-time, not a record rule: a code that expired yesterday is a valid row,
  # but choosing a past date on this form never is. Editing an expired code is
  # how you revive it, so this fires even when the date was not touched.
  def reject_past_expiry
    return unless expiry_enabled?
    return if combined_expiry&.future?

    invite.errors.add(:expires_at, 'Ta data już minęła. Wybierz późniejszą.')
  end
end
