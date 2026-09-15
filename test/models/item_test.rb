# frozen_string_literal: true

require 'test_helper'

class ItemTest < ActiveSupport::TestCase
  setup do
    @story_group = FactoryBot.create(:story_group)
    @user = FactoryBot.create(:user)
    @student = FactoryBot.create(:story_group_student, story_group: @story_group, user: @user, total_currency: 10)

    FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 0, discount: 20)

    @item = FactoryBot.create(:item, story_group: @story_group, price: 100)
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

  # --- validations ----------------------------------------------------------

  test 'an item needs a name and a rule, in Polish' do
    item = Item.new(story_group: @story_group, price: 5)

    assert_not item.valid?
    assert_equal 'Podaj nazwę przedmiotu.', item.errors[:name].first
    assert_equal 'Napisz, co przedmiot daje studentowi.', item.errors[:didactic_description].first
  end

  test 'the price floor is 1' do
    item = FactoryBot.build(:item, story_group: @story_group, price: 0)

    assert_not item.valid?
    assert_equal 'Cena musi wynosić co najmniej 1.', item.errors[:price].first
  end

  test 'icon_glyph must name one of the item presets' do
    item = FactoryBot.build(:item, story_group: @story_group, icon_glyph: 'rabbit')

    assert_not item.valid?
    assert_equal 'Nieznana grafika.', item.errors[:icon_glyph].first
  end

  test 'icon_glyph may be nil when an upload is the art' do
    item = FactoryBot.build(:item, story_group: @story_group, icon_glyph: nil)
    item.icon.attach(io: File.open(file_fixture('rank_art.png')), filename: 'art.png',
                     content_type: 'image/png',)

    assert_predicate item, :valid?
  end

  test 'an item needs art: a preset or an upload, not neither' do
    item = FactoryBot.build(:item, story_group: @story_group, icon_glyph: nil)

    assert_not item.valid?
    assert_equal 'Wybierz gotową grafikę albo wgraj własną.', item.errors[:icon_glyph].first
  end

  # --- art ------------------------------------------------------------------

  test 'art prefers the preset and upload? reports which is which' do
    item = FactoryBot.create(:item, story_group: @story_group, icon_glyph: 'flask')

    assert_equal 'flask', item.art
    assert_not item.upload?

    item.icon.attach(io: File.open(file_fixture('rank_art.png')), filename: 'art.png',
                     content_type: 'image/png',)

    # The attachment is kept so a teacher can switch back, but the preset still
    # wins while its key is set.
    assert_equal 'flask', item.art

    item.update!(icon_glyph: nil)
    assert_equal :upload, item.art
    assert_predicate item, :upload?
  end

  # Records that predate the art rule still have to render, so `art` keeps
  # answering "neither" rather than assuming one is always there.
  test 'art says neither for a record saved before art was required' do
    item = FactoryBot.create(:item, story_group: @story_group)
    item.update_column(:icon_glyph, nil)

    assert_nil item.reload.art
    assert_not item.upload?
  end

  # --- soft delete ----------------------------------------------------------

  test 'kept and deleted split the shelf' do
    kept = FactoryBot.create(:item, story_group: @story_group, name: 'Zostaje')
    gone = FactoryBot.create(:item, story_group: @story_group, name: 'Znika')
    gone.soft_delete!

    assert_includes Item.kept, kept
    assert_not_includes Item.kept, gone
    assert_includes Item.deleted, gone
    assert_predicate gone, :deleted?
  end

  test 'soft delete releases the ranks and badges the item leaned on' do
    rank = FactoryBot.create(:rank, story_group: @story_group, required_currency_value: 100)
    badge = FactoryBot.create(:badge, story_group: @story_group)
    item = FactoryBot.create(:item, story_group: @story_group,
                                    unlock_rank: rank, min_rank_for_discount: rank,)
    item.unlock_badges << badge
    item.discount_badges << badge

    item.soft_delete!
    item.reload

    # items.unlock_rank_id is a real foreign key and RanksController refuses
    # while any item holds one — an invisible item must not block a rank
    # deletion the teacher has no way to see.
    assert_nil item.unlock_rank_id
    assert_nil item.min_rank_for_discount_id
    assert_empty item.unlock_badges
    assert_empty item.discount_badges
    assert_empty rank.dependent_items
  end

  test 'a purchase still resolves its deleted item' do
    item = FactoryBot.create(:item, story_group: @story_group)
    purchase = FactoryBot.create(:students_item, story_group_student: @student, item: item)

    item.soft_delete!

    assert_equal item, purchase.reload.item
    assert_equal item.name, purchase.item.name
  end

  test 'soft delete works on a record that is no longer valid' do
    item = FactoryBot.create(:item, story_group: @story_group)
    item.update_column(:didactic_description, nil)

    assert_nothing_raised { item.reload.soft_delete! }
    assert_predicate item.reload, :deleted?
  end

  # --- ordering -------------------------------------------------------------

  test 'by_price reads the shop from cheapest' do
    # setup's @item costs 100, so it is the dear one here.
    FactoryBot.create(:item, story_group: @story_group, name: 'Drogi', price: 90)
    FactoryBot.create(:item, story_group: @story_group, name: 'Tani', price: 2)

    assert_equal %w[Tani Drogi Item], @story_group.items.by_price.pluck(:name)
  end
end
