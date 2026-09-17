# frozen_string_literal: true

class ItemsController < ApplicationController
  include StoryGroupAuthorization
  include RedesignLayout

  # Only the delete confirmation is a dialog. Creating and editing are PAGES
  # (DECISIONS.md:26) — the form carries a live preview column beside it, which
  # no dialog is wide enough for.
  layout -> { @in_modal ? false : 'redesign' }

  before_action :set_story_group

  # Teacher only, every action. Students meet items in the shop and in their
  # inventory, never here — so unlike ranks and badges this screen has no
  # second persona and no membership branch.
  before_action :authorize_story_group_manage!
  before_action :set_presentation, only: :confirm_destroy
  before_action :set_item, only: %i[edit update destroy confirm_destroy]

  # GET /story_groups/:story_group_id/items
  def index
    @shelf = Redesign::ItemShelf.new(story_group: @story_group)
  end

  # GET /story_groups/:story_group_id/items/new
  def new
    @item = @story_group.items.build(price:      Redesign::ItemShelf::DEFAULT_PRICE,
                                     icon_glyph: Redesign::Glyphs::ITEM.first,)
    set_shelf
  end

  # GET /story_groups/:story_group_id/items/:id/edit
  def edit
    set_shelf
  end

  # GET /story_groups/:story_group_id/items/:id/confirm_destroy
  def confirm_destroy
    @bought = Redesign::ItemShelf.new(story_group: @story_group).bought_for(@item)
  end

  # POST /story_groups/:story_group_id/items
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

  # PATCH/PUT /story_groups/:story_group_id/items/:id
  def update
    if @item.update(item_params)
      redirect_to story_group_items_path(@story_group),
                  notice: "Zapisano „#{@item.name}”. Zmiany dotyczą nowych zakupów."
    else
      set_shelf
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /story_groups/:story_group_id/items/:id
  #
  # Soft (DECISIONS.md:28). Nothing can refuse it: the item only leaves the
  # shop, the lists and the pickers, and every students_items row pointing at it
  # stays exactly where it was.
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

  # `kept`: a deleted item has no edit page and no delete page of its own.
  def set_item
    @item = @story_group.items.kept.find(params.expect(:id))
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  # The form needs the ladder (for the rank selects and the discount ceiling)
  # and the purchase count. Built here rather than in the view so a re-render
  # after a validation error gets it too.
  def set_shelf
    @shelf = Redesign::ItemShelf.new(story_group: @story_group)
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

    # An empty key means "use my upload" — the picker's last tile. NULL is how
    # the record says that, so normalise here rather than teaching the model
    # about a blank string.
    permitted[:icon_glyph] = permitted[:icon_glyph].presence if permitted.key?(:icon_glyph)

    # A file in this submission always wins. You just chose it, so it is the
    # art — and without JavaScript nothing else would ever select it, because
    # the picker's own tile only appears once there is something attached.
    permitted[:icon_glyph] = nil if permitted[:icon].present?
    permitted
  end
end
