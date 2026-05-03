# frozen_string_literal: true

require 'test_helper'

class ItemTest < ActiveSupport::TestCase
  def setup
    @story_group = create(:story_group)
    @user = create(:user)
    @student = create(:story_group_student, story_group: @story_group, user: @user, total_currency: 10)

    create(:rank, story_group: @story_group, required_currency_value: 0, discount: 20)

    @item = create(:item, story_group: @story_group, price: 100)
  end

  test 'discount_info_for returns a Discount object with correct value' do
    discount_info = @item.discount_info_for(@student)

    assert_instance_of Discount, discount_info
    assert_equal 20, discount_info.value
  end

  test 'discounted_price_for returns correctly calculated and rounded price' do
    @item.update!(price: 28)

    # 28 * 0.8 = 22.4, .ceil powinno dać 23
    assert_equal 23, @item.discounted_price_for(@student)
  end
end
