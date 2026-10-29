# frozen_string_literal: true

module StoryGroupsHelper
  HAND_ROTATION_STEP = 4

  def overview_teacher_lead(story_group, students_count)
    return story_group.description if story_group.description.present?

    t('story_groups.helpers.teacher_lead', count: students_count)
  end

  def overview_next_rank_line(missing, next_rank)
    line = t('story_groups.helpers.next_rank', missing: missing, rank: next_rank.name)
    return line unless next_rank.discount.to_i.positive?

    "#{line} #{t('story_groups.helpers.next_rank_discount', discount: next_rank.discount)}"
  end

  def ranking_visibility_note(story_group)
    return t('story_groups.helpers.ranking_off') unless story_group.ranking_enabled?
    return t('story_groups.helpers.ranking_full') if story_group.ranking_full?

    t('story_groups.helpers.ranking_podium')
  end

  def overview_place_line(place)
    t('story_groups.helpers.place', place: place)
  end

  def overview_hand_line(affordable)
    t('story_groups.helpers.hand', count: affordable)
  end

  def overview_hand_rotation(index, count)
    ((index - ((count - 1) / 2.0)) * HAND_ROTATION_STEP).round(1)
  end
end
