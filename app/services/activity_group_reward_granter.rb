# frozen_string_literal: true

class ActivityGroupRewardGranter
  def initialize(activity_group:, story_group:)
    @categories       = activity_group.activity_group_categories.index_by(&:id)
    @students         = story_group.student_memberships.index_by(&:id)
    @existing_rewards = StudentsActivityGroupCategory
                        .where(activity_group_category_id: @categories.keys)
                        .pluck(:activity_group_category_id, :student_id)
                        .to_set
  end

  def save(completed_pairs)
    ActiveRecord::Base.transaction do
      grant_new(completed_pairs)
    end
  end

  private

  def grant_new(completed_pairs)
    categories_to_add = completed_pairs - @existing_rewards

    categories_to_add.each do |category_id, student_id|
      next unless valid_pair?(category_id, student_id)

      category = @categories[category_id]
      student  = @students[student_id]
      grant(category: category, student: student)
    end
  end

  def valid_pair?(category_id, student_id)
    @categories[category_id] && @students[student_id]
  end

  def grant(category:, student:)
    StudentsActivityGroupCategory.create!(
      activity_group_category_id: category.id,
      student_id:                 student.id,
    )
    CurrencyTransaction.create!(
      student:         student,
      amount:          category.reward,
      transactionable: category,
      kind:            :reward,
    )
    student.increment!(:current_currency, category.reward)
    student.increment!(:total_currency, category.reward)
  end
end
