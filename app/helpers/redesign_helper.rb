# frozen_string_literal: true

# Helpers for the "Card Table" redesign layout.
module RedesignHelper
  THEME_COOKIE = :gh_theme
  THEMES       = %w[light dark].freeze

  # Renders into `data-gh-theme` on <html>.
  #
  # Returns nil when the user has expressed no preference, which lets the
  # stylesheet fall back to prefers-color-scheme. Reading the cookie
  # server-side avoids a flash of the wrong theme on first paint.
  def gh_theme
    theme = cookies[THEME_COOKIE]

    theme if THEMES.include?(theme)
  end
end
