# frozen_string_literal: true

class ItemPurchaseService
  class Result
    attr_reader :errors

    def initialize(errors = [])
      @errors = errors
    end

    def success?
      @errors.empty?
    end
  end

  def initialize(student:, item:)
    @student = student
    @item = item
    @errors = []
  end

  def call
    eligibility = PurchaseEligibilityService.new(student: @student, item: @item).call
    return Result.new(eligibility.errors) unless eligibility.eligible?

    discount_info = @item.discount_info_for(@student)
    price = PriceCalculatorService.new(price: @item.price, discount: discount_info).calculate

    if @student.current_currency < price
      return Result.new(['Masz za mało waluty, aby kupić ten przedmiot.'])
    end

    execute_purchase!(price, discount_info.value)
    notify_teachers!

    Result.new
  rescue StandardError => e
    Result.new(["Wystąpił błąd podczas zakupu: #{e.message}"])
  end

  private

  def execute_purchase!(price, discount_value)
    ActiveRecord::Base.transaction do
      @student.update!(current_currency: @student.current_currency - price)

      @student.students_items.create!(
        item:             @item,
        price_paid:       price,
        discount_applied: discount_value,
      )

      @student.currency_transactions.create!(
        amount:          -price,
        kind:            2,
        transactionable: @item,
      )
    end
  end

  def notify_teachers!
    story_group = @item.story_group
    recipients = [User.find(story_group.owner_id)]

    if story_group.respond_to?(:teachers)
      recipients += story_group.teachers.to_a
    end

    recipients.uniq.each do |teacher|
      Notification.create!(
        user:                teacher,
        story_group:         story_group,
        story_group_student: @student,
        item:                @item,
      )
    end
  end
end
