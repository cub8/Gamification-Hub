# frozen_string_literal: true

module StudentsItemsHelper
  def go_back_from_show_link(own_items, story_group:, student:, &block)
    path = if params[:back_path] == 'story_group'
             story_group_path(story_group)
           elsif own_items
             story_group_student_students_items_path(story_group, student)
           else
             story_group_student_path(story_group, student)
           end

    link_to path,
            class: 'btn btn-secondary',
            title: 'Wstecz',
            data:  { turbo_frame: '_top', turbo_prefetch: true }, &block
  end

  def close_show_link(own_items, story_group:, student:)
    if params[:back_path] == 'story_group'
      close_path = story_group_path(story_group)
      redirect_to_modal = '_top'
    elsif own_items
      close_path = story_group_student_students_items_path(story_group, student)
      redirect_to_modal = '_top'
    else
      close_path = story_group_student_path(story_group, student)
      redirect_to_modal = 'modal'
    end

    link_to 'Zamknij',
            close_path,
            class: 'btn btn-secondary',
            data:  { turbo_frame: redirect_to_modal, turbo_prefetch: true }
  end
end
