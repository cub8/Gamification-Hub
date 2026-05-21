# frozen_string_literal: true

class StudentsItemsController < ApplicationController
  before_action :set_story_group
  before_action :set_student

  def index
    authorize @student, policy_class: StudentsItemPolicy
    @students_items = policy_scope(@student.students_items).includes(:item).order(created_at: :desc)
  end

  def show
    @students_item = @student.students_items.find(params[:id])
    authorize @students_item
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def set_student
    @student = @story_group.student_memberships.find(params[:student_id])
  end
end
