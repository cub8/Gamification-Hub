# frozen_string_literal: true

# Screen-specific labels live in the screen's own helper, not in RedesignHelper.
module StudentsBadgesHelper
  # "Sebastian ma 2 z 8 odznak." — the assign dialog's sub-line.
  def badge_assign_lead(student, held, total)
    "#{student.display_name} ma #{held} z #{total} #{gh_plural(total, 'odznaki', 'odznak', 'odznak')}."
  end

  # The right-hand label on a row of the picker: what the badge is worth, or
  # that this student already has it.
  def badge_pick_status(badge, held)
    return 'Ma już' if held
    return '−0%' if badge.discount.to_i.zero?

    "−#{badge.discount.to_i}%"
  end

  # What awarding this badge will actually do. Rendered once per badge, hidden,
  # so badge_picker_controller reveals one rather than building a sentence.
  def badge_effect_sentence(badge)
    parts = [
      'Po przyznaniu: ',
      tag.b("−#{badge.discount.to_i}%"),
      ' na przedmioty, które uwzględniają tę odznakę',
    ]

    unlocking   = badge.unlocking_items.order(:name).pluck(:name)
    discounting = badge.dependent_items.order(:name).pluck(:name) - unlocking
    parts << " (#{gh_and_list(discounting)})" if discounting.any?
    parts << '.'

    parts += [' Odblokuje zakup: ', tag.b(gh_and_list(unlocking)), '.'] if unlocking.any?

    parts << ' Zobaczy ją w swojej talii.'

    safe_join(parts)
  end

  # What revoking it costs. The purchase clause only when the badge is a key to
  # something; items already bought are never taken back.
  def badge_revoke_sentence(student, badge)
    parts = [student.display_name, ' straci zniżkę ', tag.b("−#{badge.discount.to_i}%")]

    unlocking = badge.unlocking_items.order(:name).pluck(:name)
    parts << " i możliwość zakupu: #{gh_and_list(unlocking)}" if unlocking.any?

    parts << '. Kupione wcześniej przedmioty zostają.'

    safe_join(parts)
  end
end
