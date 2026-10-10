# frozen_string_literal: true

class ShopController < ApplicationController
  include StoryGroupAuthorization

  # Only the buy confirmation is a dialog; the shop itself is a page.

  # The shop renders items/_card, which is the item screens' partial. With
  # `include_all_helpers = false` that helper does not arrive on its own.
  helper ItemsHelper

  before_action :set_story_group
  before_action :authorize_story_group_read!
  # Membership, not role: `student?` asks whether this user is enrolled in THIS
  # group. A teacher who is also a participant shops here; the group's owner,
  # who is not, does not.
  before_action :authorize_shopper!
  before_action :set_student
  before_action :set_presentation, only: :confirm_buy
  before_action :set_item, only: %i[confirm_buy buy]

  # GET /story_groups/:story_group_id/shop
  def index
    @shop = shop
  end

  # GET /story_groups/:story_group_id/shop/:id/confirm_buy
  #
  # The dialog quotes a price, so the offer is re-checked here rather than
  # trusted from the page the link came off: a stale tab could otherwise show a
  # confirmation for something that has since been locked or priced out.
  def confirm_buy
    @offer = shop.offer_for(@item)

    return if shop.state_for(@item) == :afford

    redirect_to story_group_shop_index_path(@story_group),
                alert: "Nie możesz teraz kupić „#{@item.name}”."
  end

  # POST /story_groups/:story_group_id/shop/:id/buy
  def buy
    result = ItemPurchaseService.new(student: @student, item: @item).call

    if result.success?
      redirect_to story_group_shop_index_path(@story_group),
                  notice: "Kupione: „#{@item.name}”. Zostało Ci #{@student.current_currency}."
    else
      redirect_to story_group_shop_index_path(@story_group), alert: result.errors.join(', ')
    end
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def authorize_shopper!
    authorize @story_group, :student?, policy_class: StoryGroupPolicy
  end

  def set_student
    @student = @story_group.student_memberships.find_by!(user: current_user)
  end

  # `kept`: an item withdrawn from the offer cannot be bought, even by someone
  # holding a stale shop page.
  def set_item
    @item = @story_group.items.kept.find(params[:id])
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  def shop
    @shop ||= Shop.new(story_group: @story_group, student: @student)
  end
end
