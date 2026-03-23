class ItemsController < ApplicationController
  before_action :set_story_group

  def index
    @items = @story_group.items
  end

  def new
    @item = @story_group.items.build
  end

  def create
    @item = @story_group.items.build(item_params)

    if @item.save
      redirect_to story_group_items_path(@story_group), notice: "Item added successfully."
    else
      render :new
    end
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def item_params
    params.require(:item).permit(
      :name,
      :story_description,
      :didactic_description,
    )
  end
end