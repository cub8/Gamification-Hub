# frozen_string_literal: true

# Copy for the badge screens. Screen-specific labels live in the screen's own
# helper, not in ApplicationHelper.
module BadgesHelper
  # The line in the foot of a teacher's badge card (30-lists.js:32).
  def badge_holders_line(count)
    return 'Nikt jej jeszcze nie ma' if count.zero?

    "Ma ją #{count} #{gh_plural(count, 'student', 'studentów', 'studentów')}"
  end

  # The discount tag on a card, or nil when the badge gives nothing — the mockup
  # prints "−0% w sklepie", which is a promise of nothing dressed as a reward.
  def badge_discount_label(badge)
    return if badge.discount.to_i.zero?

    "−#{badge.discount}% w sklepie"
  end

  # "Jak zdobyć" as the card shows it. The placeholder is only ever reached in
  # the form preview, before the field has been typed into — the model requires
  # this text on a saved badge.
  def badge_rule(badge)
    badge.didactic_description.presence || 'Jak zdobyć…'
  end

  def badge_name(badge)
    badge.name.presence || 'Nazwa odznaki'
  end

  # The subtitle under a badge in the award dialog's thumbnail row
  # (30-br.js:69): the story if there is one, otherwise the rule.
  def badge_thumb_subtitle(badge)
    badge.story_description.presence || badge.didactic_description.presence || ''
  end
end
