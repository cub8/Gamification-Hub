# frozen_string_literal: true

module BadgesHelper
  def badge_holders_line(count)
    return 'Nikt jej jeszcze nie ma' if count.zero?

    "Ma ją #{count} #{gh_plural(count, 'student', 'studentów', 'studentów')}"
  end

  def badge_discount_label(badge)
    return if badge.discount.to_i.zero?

    "−#{badge.discount}% w sklepie"
  end

  def badge_rule(badge)
    badge.didactic_description.presence || 'Jak zdobyć…'
  end

  def badge_name(badge)
    badge.name.presence || 'Nazwa odznaki'
  end

  def badge_thumb_subtitle(badge)
    badge.story_description.presence || badge.didactic_description.presence || ''
  end
end
