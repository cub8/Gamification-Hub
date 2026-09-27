# frozen_string_literal: true

module StoryGroupsHelper
  HAND_ROTATION_STEP = 4

  def overview_teacher_lead(story_group, students_count)
    return story_group.description if story_group.description.present?

    "#{students_count} #{gh_plural(students_count, 'student', 'studenci', 'studentów')} w tej grupie. " \
      'Dodaj opis w ustawieniach, żeby powitać nowe osoby.'
  end

  def overview_next_rank_line(missing, next_rank)
    line = "Jeszcze #{missing} do rangi #{next_rank.name}."
    return line unless next_rank.discount.to_i.positive?

    "#{line} Ta ranga daje −#{next_rank.discount}% w sklepie."
  end

  def ranking_visibility_note(story_group)
    return 'Ranking jest wyłączony — studenci nie widzą tego podium.' unless story_group.ranking_enabled?
    return 'Studenci widzą pełny ranking, pod pseudonimami.' if story_group.ranking_full?

    'Studenci widzą podium i własne miejsce, pod pseudonimami.'
  end

  def overview_place_line(place)
    "#{place}. miejsce w rankingu grupy"
  end

  def overview_hand_line(affordable)
    "Dobierz coś w sklepie. Stać cię teraz na #{affordable} " \
      "#{gh_plural(affordable, 'przedmiot', 'przedmioty', 'przedmiotów')}."
  end

  def overview_hand_rotation(index, count)
    ((index - ((count - 1) / 2.0)) * HAND_ROTATION_STEP).round(1)
  end
end
