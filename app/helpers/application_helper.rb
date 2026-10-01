# frozen_string_literal: true

module ApplicationHelper
  THEME_COOKIE = :gh_theme
  THEMES       = %w[light dark].freeze

  def transaction_description(transaction, story_group)
    student_name = transaction.student.full_name
    case transaction.kind
    when 'purchase'
      item_name = transaction.transactionable&.name || 'przedmiot'
      "#{student_name} zakupił #{item_name} za #{transaction.amount.abs} #{story_group.currency_name}"
    when 'reward'
      category_name = transaction.transactionable&.didactic_description || 'aktywność'
      "#{student_name} zdobył nagrodę za: #{category_name}"
    when 'adjustment'
      sign = transaction.amount >= 0 ? '+' : ''
      adjuster = transaction.granted_by_user&.full_name || 'nauczyciel'
      "#{adjuster} skorygował walutę #{student_name} (#{sign}#{transaction.amount})"
    end
  end

  def gh_theme
    theme = cookies[THEME_COOKIE]

    theme if THEMES.include?(theme)
  end

  def gh_mmss(seconds)
    format('%<m>d:%<s>02d', m: seconds / 60, s: seconds % 60)
  end

  def gh_group_chrome
    return @gh_group_chrome if defined?(@gh_group_chrome)

    @gh_group_chrome = GroupChrome.for(user: @current_user, story_group: @story_group)
  end

  def gh_plural(count, one, few, many)
    Plural.pick(count, one, few, many)
  end

  def gh_minutes(count)
    "#{count} #{gh_plural(count, 'minuta', 'minuty', 'minut')}"
  end

  def gh_initials(name)
    name.to_s.split(/\s+/).reject(&:empty?).first(2).map { |word| word[0].upcase }
                                                    .join
  end

  def gh_monogram(name)
    words = name.to_s.split(/\s+/).select { |word| word.length > 2 }
    words = name.to_s.split(/\s+/) if words.empty?

    words.first(2)
         .map { |word| word[0].to_s.upcase }
         .join
  end

  def gh_avatar_hue(name)
    name.to_s.each_char.sum(&:ord) % 5
  end

  def gh_when(time)
    case time.to_date
    when Date.current   then "dziś #{time.strftime('%H:%M')}"
    when Date.yesterday then "wczoraj #{time.strftime('%H:%M')}"
    else                     time.strftime('%d.%m, %H:%M')
    end
  end

  def gh_stamp(time)
    time.strftime('%d.%m, %H:%M')
  end

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

  def gh_percent(value, max)
    return 100 if max.to_i <= 0

    ((value.to_f / max) * 100).round.clamp(0, 100)
  end

  def gh_and_list(items)
    list = Array(items)
    return list.first.to_s if list.size < 2

    "#{list[0..-2].join(', ')} i #{list.last}"
  end

  def gh_glyph(key, css_class: 'gh-card-art-glyph')
    markup = Glyphs.markup(key)
    return if markup.nil?

    tag.svg(markup.html_safe, class: css_class, viewBox: '0 0 64 64', 'aria-hidden': 'true')
  end

  def gh_group_art(key)
    return unless GroupArt.include?(key)

    image_tag GroupArt.asset_for(key), alt: ''
  end

  def gh_group_cover(story_group)
    return image_tag(story_group.icon, alt: '') if story_group.art == :upload

    gh_group_art(story_group.icon_glyph)
  end

  def gh_group_cover_url(story_group)
    return if story_group.nil?
    return url_for(story_group.icon) if story_group.art == :upload
    return unless GroupArt.include?(story_group.icon_glyph)

    asset_path(GroupArt.asset_for(story_group.icon_glyph))
  end

  def gh_currency_mark(story_group)
    return image_tag(story_group.currency_icon, alt: '') if story_group.currency_art == :upload

    gh_currency_icon(story_group.currency_icon_glyph)
  end

  def gh_currency_icon(key, css_class: 'gh-coin-mark')
    markup = CurrencyIcons.markup(key)
    return if markup.nil?

    tag.svg(markup.html_safe, class: css_class, viewBox: '0 0 24 24', 'aria-hidden': 'true')
  end
end
