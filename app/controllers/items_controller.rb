# frozen_string_literal: true

class ItemsController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group

  before_action :authorize_story_group_manage!
  before_action :set_presentation, only: :confirm_destroy
  before_action :set_item, only: %i[edit update destroy confirm_destroy]

  def index
    @shelf = ItemShelf.new(story_group: @story_group)
  end

  def new
    @item = @story_group.items.build(price:      ItemShelf::DEFAULT_PRICE,
                                     icon_glyph: Glyphs::ITEM.first,)
    set_shelf
  end

  def edit
    set_shelf
  end

  def confirm_destroy
    @bought = ItemShelf.new(story_group: @story_group).bought_for(@item)
  end

  def create
    @item = @story_group.items.build(item_params)

    if @item.save
      redirect_to story_group_items_path(@story_group),
                  notice: "Dodano przedmiot „#{@item.name}” do sklepu."
    else
      set_shelf
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @item.update(item_params)
      redirect_to story_group_items_path(@story_group),
                  notice: "Zapisano „#{@item.name}”. Zmiany dotyczą nowych zakupów."
    else
      set_shelf
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    name = @item.name
    @item.soft_delete!

    redirect_outside_turbo_frame story_group_items_path(@story_group),
                                 notice: "Usunięto „#{name}” z oferty. " \
                                         'Kupione egzemplarze zostają u studentów.'
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_item
    @item = @story_group.items.kept.find(params.expect(:id))
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  def set_shelf
    @shelf = ItemShelf.new(story_group: @story_group)
  end

  def item_params
    permitted = params.expect(
      item: [
        :name,
        :story_description,
        :didactic_description,
        :price,
        :icon,
        :icon_glyph,
        :can_buy_at_0_lives,
        :unlock_rank_id,
        :min_rank_for_discount_id,
        { unlock_badge_ids: [] },
        { discount_badge_ids: [] },
      ],
    )

    permitted[:icon_glyph] = permitted[:icon_glyph].presence if permitted.key?(:icon_glyph)
    permitted[:icon_glyph] = nil if permitted[:icon].present?
    permitted
  end
end
