# frozen_string_literal: true

# Grants the rewards a teacher marked on a grading sheet.
#
# The one rule this service exists to enforce: awards only ever go *on*. A pair
# missing from the submitted set is not a revocation, it is simply not a new
# award — which is what "nie można cofnąć" means on the grade screen and why
# the review dialog in front of it matters.
class ActivityGroupRewardGranter
  # `total`, not `sum`: Struct members shadow Enumerable#sum.
  Result = Struct.new(:pairs, :total, :students) do
    def any? = pairs.any?
  end

  def initialize(activity_group:, story_group:)
    # Hidden columns are out of the grading table, so they cannot take new
    # awards either — otherwise a hand-built request could still pay one out.
    @categories       = activity_group.activity_group_categories.reject(&:hidden?).index_by(&:id)
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
    granted = []
    sum     = 0

    (completed_pairs - @existing_rewards).each do |category_id, student_id|
      next unless valid_pair?(category_id, student_id)

      category = @categories[category_id]
      grant(category: category, student: @students[student_id])
      granted << [category_id, student_id]
      sum += category.reward.to_i
    end

    Result.new(granted, sum, granted.map(&:last).uniq.size)
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
