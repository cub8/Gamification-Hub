# frozen_string_literal: true

require 'test_helper'

class ItemPurchaseServiceConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @story_group = FactoryBot.create(:story_group)
    @owner = @story_group.owner
    @user = FactoryBot.create(:user)
    @student = FactoryBot.create(:story_group_student,
                                 story_group:      @story_group,
                                 user:             @user,
                                 current_currency: 60,
                                 lives:            1,)
    @item = FactoryBot.create(:item, story_group: @story_group, price: 60)
  end

  teardown do
    Notification.where(story_group_student_id: @student.id).delete_all if @student
    CurrencyTransaction.where(student_id: @student.id).delete_all if @student
    StudentsItem.where(story_group_student_id: @student.id).delete_all if @student
    @student&.destroy
    @item&.destroy
    @story_group&.destroy
    @user&.destroy
    @owner&.destroy
  end

  test 'two concurrent purchases cannot both spend the same balance' do
    entered_lock = Queue.new
    release_lock = Queue.new

    original = ItemPurchaseService.instance_method(:execute_purchase!)
    ItemPurchaseService.__send__(:define_method, :execute_purchase!) do |price, discount_value|
      if Thread.current[:pause_inside_lock]
        entered_lock << true
        release_lock.pop
      end
      original.bind(self).call(price, discount_value)
    end

    result_a = nil
    thread_a = Thread.new do
      Thread.current[:pause_inside_lock] = true
      result_a = ItemPurchaseService.new(student: StoryGroupStudent.find(@student.id), item: @item).call
    end

    entered_lock.pop

    result_b = nil
    thread_b = Thread.new do
      result_b = ItemPurchaseService.new(student: StoryGroupStudent.find(@student.id), item: @item).call
    end

    blocked = !thread_b.join(0.3)

    release_lock << true
    thread_a.join(2)
    thread_b.join(2)

    ItemPurchaseService.__send__(:define_method, :execute_purchase!, original)

    assert blocked, 'second purchase should block while the student row is locked'
    assert result_a&.success?
    refute result_b&.success?
    assert_equal 0, @student.reload.current_currency
    assert_equal 1, @student.students_items.count
  end
end
