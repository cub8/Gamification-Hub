# frozen_string_literal: true

module StudentsItemsHelper
  def go_back_from_show_link(own_items, story_group:, student:, &block)
    back_frame = own_items ? '_top' : 'modal'

    link_to story_group_student_students_items_path(story_group, student),
            class: 'btn btn-secondary',
            title: 'Do listy przedmiotów',
            data:  { turbo_frame: back_frame, turbo_prefetch: true }, &block
  end

  def close_show_link(own_items, story_group:, student:)
    if own_items
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
