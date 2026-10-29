# frozen_string_literal: true

module BadgesHelper
  def badge_holders_line(count)
    return t('badges.helpers.nobody_holds') if count.zero?

    t('badges.helpers.holders', count: count)
  end

  def badge_discount_label(badge)
    return if badge.discount.to_i.zero?

    t('badges.helpers.discount', discount: badge.discount)
  end

  def badge_rule(badge)
    badge.didactic_description.presence || t('badges.helpers.rule_placeholder')
  end

  def badge_name(badge)
    badge.name.presence || t('badges.helpers.name_placeholder')
  end

  def badge_thumb_subtitle(badge)
    badge.story_description.presence || badge.didactic_description.presence || ''
  end
end
