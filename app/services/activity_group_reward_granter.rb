# frozen_string_literal: true

class ActivityGroupRewardGranter
  def initialize(category:, student:)
    @category = category
    @student  = student
  end

  def grant
    ActiveRecord::Base.transaction do
      record = StudentActivityGroupCategory.find_or_create_by(
        activity_group_category_id: @category.id,
        student_id:                 @student.id,
      )
      return unless record.previously_new_record?

      @student.increment!(:current_currency, @category.reward)
      @student.increment!(:total_currency, @category.reward)
    end
  end

  def revoke
    ActiveRecord::Base.transaction do
      record = StudentActivityGroupCategory.find_by(
        activity_group_category_id: @category.id,
        student_id:                 @student.id,
      )
      return unless record

      record.destroy!
      @student.decrement!(:current_currency, @category.reward)
      @student.decrement!(:total_currency, @category.reward)
    end
  end
end
