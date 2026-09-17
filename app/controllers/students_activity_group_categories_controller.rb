# frozen_string_literal: true

# The grading table — "Ocenianie". One PATCH grants every marked cell at once,
# and nothing here can take an award back.
class StudentsActivityGroupCategoriesController < ApplicationController
  include StoryGroupAuthorization
  include RedesignLayout

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :set_activity_group

  # GET .../activity_groups/:activity_group_id/students_activity_group_categories/edit
  def edit
    @sheet = Redesign::GradeSheet.new(@activity_group)

    # Cells granted by the request that just redirected here, so they can play
    # the stamp animation instead of simply being locked on arrival.
    @awarded_pairs = Array(flash[:awarded_pairs]).to_set { |pair| pair.map(&:to_i) }

  end

  # PATCH .../activity_groups/:activity_group_id/students_activity_group_categories
  def update
    result = ActivityGroupRewardGranter.new(activity_group: @activity_group, story_group: @story_group)
                                       .save(parsed_reward_params)

    flash[:awarded_pairs] = result.pairs
    redirect_to edit_story_group_activity_group_students_activity_group_categories_path(@story_group,
                                                                                        @activity_group,),
                notice: award_notice(result), status: :see_other
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_activity_group
    @activity_group = @story_group.activity_groups.kept.find(params.expect(:activity_group_id))
  end

  def award_notice(result)
    return 'Nie zaznaczono żadnego pola.' if result.pairs.none?

    students = helpers.gh_plural(result.students, 'studentowi', 'studentom', 'studentom')
    "Przyznano #{result.total} #{@story_group.currency_name} #{result.students} #{students}."
  end

  # `completions[student_id][category_id]`. A missing key is not a revocation —
  # submitting nothing grants nothing, it does not clear the sheet. There is no
  # way to un-grant, by design.
  def parsed_reward_params
    set = Set.new
    params.expect(completions: {}).each do |student_id, category_hash|
      category_hash.each_key { |category_id| set.add([category_id.to_i, student_id.to_i]) }
    end
    set
  rescue ActionController::ParameterMissing
    set
  end
end
