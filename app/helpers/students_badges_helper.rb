# frozen_string_literal: true

# Screen-specific labels live in the screen's own helper, not in ApplicationHelper.
module StudentsBadgesHelper
  # "Sebastian ma 2 z 8 odznak." — the assign dialog's sub-line.
  def badge_assign_lead(student, held, total)
    t('students_badges.helpers.assign_lead', name: student.display_name, held: held, count: total)
  end

  # The right-hand label on a row of the picker: what the badge is worth, or
  # that this student already has it.
  def badge_pick_status(badge, held)
    return t('students_badges.helpers.owned') if held
    return '−0%' if badge.discount.to_i.zero?

    "−#{badge.discount.to_i}%"
  end

  # What awarding this badge will actually do. Rendered once per badge, hidden,
  # so badge_picker_controller reveals one rather than building a sentence.
  def badge_effect_sentence(badge)
    unlocking   = badge.unlocking_items.order(:name).pluck(:name)
    discounting = badge.dependent_items.order(:name).pluck(:name) - unlocking

    t('students_badges.helpers.effect_html',
      discount:    tag.b("−#{badge.discount.to_i}%"),
      discounting: badge_effect_discounting(discounting),
      unlocks:     badge_effect_unlocks(unlocking),)
  end

  def badge_effect_discounting(names)
    return '' if names.empty?

    t('students_badges.helpers.effect_discounting', items: gh_and_list(names))
  end

  def badge_effect_unlocks(names)
    return '' if names.empty?

    t('students_badges.helpers.effect_unlocks_html', items: tag.b(gh_and_list(names)))
  end

  # What revoking it costs. The purchase clause only when the badge is a key to
  # something; items already bought are never taken back.
  def badge_revoke_sentence(student, badge)
    unlocking = badge.unlocking_items.order(:name).pluck(:name)

    t('students_badges.helpers.revoke_html',
      name:      student.display_name,
      discount:  tag.b("−#{badge.discount.to_i}%"),
      unlocking: unlocking.any? ? t('students_badges.helpers.revoke_unlocking', items: gh_and_list(unlocking)) : '',)
  end
end
