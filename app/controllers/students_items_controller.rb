# frozen_string_literal: true

class StudentsItemsController < ApplicationController
  before_action :set_story_group
  before_action :set_student
  before_action :authorize_access!
  before_action :set_own_items

  def index
    @students_items = @student.students_items.includes(item: { image_attachment: :blob }).order(created_at: :desc)
  end

  def show
    @students_item = @student.students_items.find(params[:id])
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def set_student
    @student = @story_group.student_memberships.find(params[:student_id])
  end

  def set_own_items
    @own_items = current_user == @student.user
  end

  def authorize_access!
    return if current_user.teacher?
    return if @story_group.owner_id == current_user.id
    return if current_user == @student.user

    redirect_to home_path, alert: 'Brak dostępu do tej akcji.'
  end
end
