# frozen_string_literal: true

class InviteForm
  include ApplicationHelper

  PERMITTED = %i[limit_enabled max_uses expiry_enabled expires_on expires_time].freeze
  DEFAULT_MAX_USES = 30
  DEFAULT_TIME     = '23:59'

  attr_reader :invite, :max_uses, :expires_on, :expires_time

  class << self
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

  def save
    invite.max_uses   = limit_enabled? ? max_uses : nil
    invite.expires_at = expiry_enabled? ? combined_expiry : nil

    invite.validate
    reject_past_expiry

    invite.errors.empty? && invite.save
  end

  def error_for(attribute) = invite.errors[attribute].first

  def summary
    text(:sentence, limit: limit_phrase, expiry: expiry_phrase)
  end

  def unit_label = text(:unit, count: max_uses.to_i)

  private

  def text(key, **) = I18n.t("story_group_invites.summary.#{key}", **)

  def limit_phrase
    return text(:no_limit) unless limit_enabled?

    text(:limit, count: max_uses.to_i)
  end

  def expiry_phrase
    return text(:no_expiry) unless expiry_enabled?

    text(:expiry, date: gh_stamp(combined_expiry))
  end

  def combined_expiry
    @combined_expiry ||= Time.zone.parse("#{expires_on} #{expires_time}")
  end

  def reject_past_expiry
    return unless expiry_enabled?
    return if combined_expiry&.future?

    invite.errors.add(:expires_at, :past)
  end
end
