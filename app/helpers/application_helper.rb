# frozen_string_literal: true

module ApplicationHelper
  THEME_COOKIE = :gh_theme
  THEMES       = %w[light dark].freeze

  def transaction_description(transaction, story_group)
    student_name = transaction.student.full_name
    case transaction.kind
    when 'purchase'
      item_name = transaction.transactionable&.name || t('application.helpers.transaction.item_fallback')
      t('application.helpers.transaction.purchase', student:  student_name,
                                                    item:     item_name,
                                                    amount:   transaction.amount.abs,
                                                    currency: story_group.currency_name,)
    when 'reward'
      category_name = transaction.transactionable&.didactic_description ||
                      t('application.helpers.transaction.category_fallback')
      t('application.helpers.transaction.reward', student: student_name, category: category_name)
    when 'adjustment'
      sign = transaction.amount >= 0 ? '+' : ''
      adjuster = transaction.granted_by_user&.full_name || t('application.helpers.transaction.adjuster_fallback')
      t('application.helpers.transaction.adjustment', adjuster: adjuster,
                                                      student:  student_name,
                                                      amount:   "#{sign}#{transaction.amount}",)
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

  def gh_minutes(count)
    t('application.helpers.minutes', count: count)
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
    when Date.current   then t('application.helpers.today', time: l(time, format: :gh_time))
    when Date.yesterday then t('application.helpers.yesterday', time: l(time, format: :gh_time))
    else                     l(time, format: :gh_day_time)
    end
  end

  # I18n.l rather than l: InviteForm calls this outside a view.
  def gh_stamp(time)
    I18n.l(time, format: :gh_day_time)
  end

  def gh_feed_title(transaction)
    subject = transaction.transactionable

    case transaction.kind.to_sym
    when :purchase
      if subject
        t('application.helpers.feed.purchase', name: subject.name)
      else
        t('application.helpers.feed.purchase_fallback')
      end
    when :reward
      subject&.story_description.presence || subject&.didactic_description.presence ||
        t('application.helpers.feed.reward_fallback')
    else
      t('application.helpers.feed.adjustment')
    end
  end

  def gh_percent(value, max)
    return 100 if max.to_i <= 0

    ((value.to_f / max) * 100).round.clamp(0, 100)
  end

  # Fills a translated template whose slots hold markup rather than text:
  #   gh_fill(t('items.sentences.max'), holder: ..., percent: tag.b('20%'))
  # Text around the slots is escaped; html_safe values (tag.b, safe_join) pass
  # through. item_form_controller.ts fills the same templates on the client.
  def gh_fill(template, **vars)
    parts = template.to_s.split(/(%\{\w+\})/).map do |part|
      key = part[/\A%\{(\w+)\}\z/, 1]
      key ? vars[key.to_sym] : part
    end

    safe_join(parts)
  end

  # "a, b i c" in Polish, "a, b and c" in English (connectors from rails-i18n).
  def gh_and_list(items)
    Array(items).map(&:to_s).to_sentence
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
