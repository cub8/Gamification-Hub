# frozen_string_literal: true

class ActivityGroupRewardGranter
  def initialize(activity_group:, story_group:)
    @activity_group = activity_group
    @story_group    = story_group
  end

  def save(completed_pairs)
    categories   = @activity_group.activity_group_categories.index_by(&:id)
    students     = @story_group.student_memberships.index_by(&:id)
    existing     = StudentActivityGroupCategory
                   .where(activity_group_category_id: categories.keys)
                   .index_by { |c| [c.activity_group_category_id, c.student_id] }
    existing_set = existing.keys.to_set

    ActiveRecord::Base.transaction do
      (completed_pairs - existing_set).each do |cat_id, student_id|
        next unless categories[cat_id] && students[student_id]

        grant(category: categories[cat_id], student: students[student_id])
      end

      (existing_set - completed_pairs).each do |cat_id, student_id|
        next unless existing[[cat_id, student_id]] && categories[cat_id] && students[student_id]

        revoke(completion: existing[[cat_id, student_id]], category: categories[cat_id], student: students[student_id])
      end
    end
  end

  private

  def grant(category:, student:)
    StudentActivityGroupCategory.create!(
      activity_group_category_id: category.id,
      student_id:                 student.id,
    )
    student.increment!(:current_currency, category.reward)
    student.increment!(:total_currency, category.reward)
  end

  def revoke(completion:, category:, student:)
    completion.destroy!
    student.decrement!(:current_currency, category.reward)
    student.decrement!(:total_currency, category.reward)
  end
end
