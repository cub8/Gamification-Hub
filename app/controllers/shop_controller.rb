# frozen_string_literal: true

class ShopController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_read!
  before_action :set_student

  def index
    authorize @story_group, :student?, policy_class: StoryGroupPolicy
    @items = @story_group.items.with_attached_image.includes(:unlock_rank, :min_rank_for_discount, :unlock_badges,
                                                             :discount_badges,)

    @discount_infos    = {}
    @discounted_prices = {}
    eligibilities      = {}

    @items.each do |item|
      discount                    = item.discount_info_for(@student)
      @discount_infos[item.id]    = discount
      @discounted_prices[item.id] = PriceCalculatorService.new(price: item.price, discount: discount).calculate
      eligibilities[item.id]      = PurchaseEligibilityService.new(student: @student, item: item).call
    end

    @eligible_items, @locked_items = @items.partition { |i| eligibilities[i.id].eligible? }
  end

  def show
    authorize @story_group, :student?, policy_class: StoryGroupPolicy
    @item             = @story_group.items.find(params[:id])
    @discount_info    = @item.discount_info_for(@student)
    @discounted_price = PriceCalculatorService.new(price: @item.price, discount: @discount_info).calculate
    @eligibility      = PurchaseEligibilityService.new(student: @student, item: @item).call
  end

  def buy
    @item = Item.find(params[:id])

    result = ItemPurchaseService.new(student: @student, item: @item).call

    if result.success?
      redirect_to story_group_shop_index_path(@story_group), notice: 'Przedmiot został pomyślnie kupiony!'
    else
      redirect_to story_group_shop_index_path(@story_group), alert: result.errors.join(', ')
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
