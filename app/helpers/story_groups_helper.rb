# frozen_string_literal: true

# Screen-specific labels live in the screen's own helper, not in ApplicationHelper.
# Everything here belongs to "Grupa: przegląd" (#/t/home and #/s/home).
module StoryGroupsHelper
  # The teacher's lead, under the group's name in the hero. The description is
  # the group's own voice, so it is shown as written; this only fills the
  # silence when there is none.
  def overview_teacher_lead(story_group, students_count)
    return story_group.description if story_group.description.present?

    "#{students_count} #{gh_plural(students_count, 'student', 'studenci', 'studentów')} w tej grupie. " \
      'Dodaj opis w ustawieniach, żeby powitać nowe osoby.'
  end

  # "Jeszcze 8 do rangi Kosmiczny Królik. Ta ranga daje −15% w sklepie."
  # The discount clause is dropped when the rung carries none — promising a
  # discount of zero is worse than promising nothing.
  def overview_next_rank_line(missing, next_rank)
    line = "Jeszcze #{missing} do rangi #{next_rank.name}."
    return line unless next_rank.discount.to_i.positive?

    "#{line} Ta ranga daje −#{next_rank.discount}% w sklepie."
  end

  # What the students make of a sheet's podium. It is the teacher's own data,
  # so it is always shown here; this says how much of it reaches them, which
  # depends on the group's ranking settings (DECISIONS.md:36).
  def ranking_visibility_note(story_group)
    return 'Ranking jest wyłączony — studenci nie widzą tego podium.' unless story_group.ranking_enabled?
    return 'Studenci widzą pełny ranking, pod pseudonimami.' if story_group.ranking_full?

    'Studenci widzą podium i własne miejsce, pod pseudonimami.'
  end

  # "2. miejsce w rankingu grupy".
  def overview_place_line(place)
    "#{place}. miejsce w rankingu grupy"
  end

  # The dashed slot that closes the hand. Same sentence the inventory screen
  # uses, because it is the same invitation.
  def overview_hand_line(affordable)
    "Dobierz coś w sklepie. Stać cię teraz na #{affordable} " \
      "#{gh_plural(affordable, 'przedmiot', 'przedmioty', 'przedmiotów')}."
  end

  # How far the fan rotates one card: the middle card sits straight, the rest
  # splay to either side of it. handCard() (30-main.js:74) steps by 6°; this
  # steps by 4°.
  #
  # The step is what decides how far the fan reaches sideways, and it reaches
  # further than it looks: the pivot sits BELOW the card, so a corner swings out
  # by roughly (1.2 × card height) × sin(angle) — about 87px a side at 12°,
  # 29px at 8°. Four degrees is the most that stays inside the padding the zone
  # can afford.
  HAND_ROTATION_STEP = 4

  def overview_hand_rotation(index, count)
    ((index - ((count - 1) / 2.0)) * HAND_ROTATION_STEP).round(1)
  end
end
