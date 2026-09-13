# frozen_string_literal: true

# Helpers for the "Card Table" redesign layout.
module RedesignHelper
  THEME_COOKIE = :gh_theme
  THEMES       = %w[light dark].freeze

  # Icons are Font Awesome, written inline in views as `%i.fa-solid.fa-envelope`
  # exactly like the legacy views — there is no icon helper here on purpose.
  # Sizing per context lives in redesign/components/icons.css.

  # Renders into `data-gh-theme` on <html>.
  #
  # Returns nil when the user has expressed no preference, which lets the
  # stylesheet fall back to prefers-color-scheme. Reading the cookie
  # server-side avoids a flash of the wrong theme on first paint.
  def gh_theme
    theme = cookies[THEME_COOKIE]

    theme if THEMES.include?(theme)
  end

  # "1:00", "0:59", "0:07". The mockup zero-pads the whole value and so renders
  # a literal "0:60" on its first tick — that is a mockup bug, not a spec.
  def gh_mmss(seconds)
    format('%<m>d:%<s>02d', m: seconds / 60, s: seconds % 60)
  end

  # Polish plural picker: 1 -> one, 2-4 -> few, otherwise many, with the usual
  # 12-14 exception (12 minut, not 12 minuty). The app has no rails-i18n, so
  # Polish copy is written inline as everywhere else; this keeps the form right
  # when the number is dynamic. Mirrors the mockup's `pl()` (00-shared.js:4).
  def gh_plural(count, one, few, many)
    n        = count.abs
    last_two = n % 100
    last_one = n % 10

    return one if n == 1
    return few if last_one.between?(2, 4) && !last_two.between?(12, 14)

    many
  end

  # "5 minut", "1 minuta", "3 minuty".
  def gh_minutes(count)
    "#{count} #{gh_plural(count, 'minuta', 'minuty', 'minut')}"
  end

  # Up to two initials, for the avatar and the group-thumbnail fallback.
  def gh_initials(name)
    name.to_s.split(/\s+/).reject(&:empty?).first(2).map { |word| word[0].upcase }
                                                    .join
  end

  # Monogram for a group with no artwork uploaded. Unlike gh_initials this
  # skips short words, so "Wstęp do algorytmiki" reads "WA" and not "WD".
  # Mirrors the mockup's `mono()` (30-gh.js:23).
  def gh_monogram(name)
    words = name.to_s.split(/\s+/).select { |word| word.length > 2 }
    words = name.to_s.split(/\s+/) if words.empty?

    words.first(2)
         .map { |word| word[0].to_s.upcase }
         .join
  end

  # Which of the five avatar tints a name gets. Stable for a given name and
  # deliberately not tied to the user id, so the same person is the same colour
  # wherever they appear. Mirrors the mockup's `hue()` (00-shared.js:167).
  def gh_avatar_hue(name)
    name.to_s.each_char.sum(&:ord) % 5
  end

  # "dziś 10:20", "wczoraj 14:02", "11.09, 09:05" — the mockup's own phrasing
  # for a timestamp in a feed, where the day matters more than the date.
  def gh_when(time)
    case time.to_date
    when Date.current   then "dziś #{time.strftime('%H:%M')}"
    when Date.yesterday then "wczoraj #{time.strftime('%H:%M')}"
    else                     time.strftime('%d.%m, %H:%M')
    end
  end

  # One line describing a currency movement, for the cross-group feed.
  #
  # `transactionable` is polymorphic and optional, and an Item can be hard
  # deleted today, so every branch has to survive a nil.
  def gh_feed_title(transaction)
    subject = transaction.transactionable

    case transaction.kind.to_sym
    when :purchase
      subject ? "Zakup: #{subject.name}" : 'Zakup'
    when :reward
      subject&.story_description.presence || subject&.didactic_description.presence || 'Nagroda za aktywność'
    else
      'Korekta waluty'
    end
  end

  # Clamped integer percentage for the rank progress bar.
  def gh_percent(value, max)
    return 100 if max.to_i <= 0

    ((value.to_f / max) * 100).round.clamp(0, 100)
  end
end
