# frozen_string_literal: true

module Localization
  extend ActiveSupport::Concern

  LOCALE_COOKIE = :locale

  included do
    around_action :switch_locale
  end

  protected

  # A block keeps the locale from leaking into the next request served by the same thread.
  def switch_locale(&)
    I18n.with_locale(requested_locale, &)
  end

  def requested_locale
    [cookies[LOCALE_COOKIE], browser_locale].find { |locale| available_locale?(locale) } || I18n.default_locale
  end

  # "en-US,en;q=0.9,pl;q=0.8" -> "en". Browsers list languages in order of preference.
  def browser_locale
    request.headers['Accept-Language'].to_s.split(',')
           .map { |entry| entry.strip.first(2).downcase }
           .find { |locale| available_locale?(locale) }
  end

  def available_locale?(locale)
    I18n.available_locales.map(&:to_s).include?(locale.to_s)
  end
end
