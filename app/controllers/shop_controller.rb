# frozen_string_literal: true

class ShopController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_read!
  before_action :set_student

  def index
    authorize @story_group, :student?, policy_class: StoryGroupPolicy
    @items = @story_group.items.includes(:unlock_rank, :min_rank_for_discount, :unlock_badges, :discount_badges)
  end

  def show
    authorize @story_group, :student?, policy_class: StoryGroupPolicy
    @item = @story_group.items.find(params[:id])
  end

  def buy
    @item = Item.find(params[:id])

    result = ItemPurchaseService.new(student: @student, item: @item).call

    if result.success?
      redirect_to story_group_shop_index_path(@story_group), notice: 'Przedmiot został pomyślnie kupiony!'
    else
      redirect_to story_group_shop_path(@story_group, @item), alert: result.errors.join(', ')
    end
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def set_student
    @student = @story_group.student_memberships.find_by!(user: current_user)
  end
end
