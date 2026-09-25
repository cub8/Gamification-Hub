# frozen_string_literal: true

class StudentsItemsController < ApplicationController
  # The inventory renders the item card's art partial, and with
  # `include_all_helpers = false` that helper does not arrive on its own.
  helper ItemsHelper

  before_action :set_story_group
  before_action :set_student
  before_action :set_own_items

  # GET /story_groups/:story_group_id/students/:student_id/items
  #
  # "Moje przedmioty" for the student themselves. A teacher normally reads the
  # same rows on the Przedmioty tab of the student sheet, but the URL still
  # answers them — `@own_items` is what decides the wording, as it always has.
  def index
    authorize @student, policy_class: StudentsItemPolicy

    @purchases = policy_scope(@student.students_items)
                 .includes(item: { icon_attachment: :blob })
                 .order(created_at: :desc, id: :desc)

    # Only for the student's own screen: the closing slot invites them back to
    # the shop, which means nothing when a teacher is reading.
    @shop = Shop.new(story_group: @story_group, student: @student) if @own_items
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_student
    @student = @story_group.student_memberships.with_user.find(params.expect(:student_id))
  end

  def set_own_items
    @own_items = current_user == @student.user
  end
end
