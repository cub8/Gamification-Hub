# frozen_string_literal: true

class ItemsController < ApplicationController
  before_action :set_story_group
  before_action :set_item, only: %i[edit update destroy]
  before_action :authorize_story_group!

  def index
    @items = policy_scope(@story_group.items)
  end

  def new
    @item = @story_group.items.build
  end

  def edit; end

  def create
    @item = @story_group.items.build(item_params)

    if @item.save
      redirect_to story_group_items_path(@story_group)
    else
      render :new
    end
  end

  def update
    if @item.update(item_params)
      redirect_to story_group_items_path(@story_group)
    else
      render :edit
    end
  end

  def destroy
    @item.destroy

    redirect_to story_group_items_path(@story_group)
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def set_item
    @item = @story_group.items.find(params[:id])
  end

  def authorize_story_group!
    authorize @story_group, :update?
  end

  def item_params
    params.require(:item).permit(
      :name,
      :story_description,
      :didactic_description,
      :price,
      :image,
      :can_buy_at_0_lives,
    )
  end
end
