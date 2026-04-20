# frozen_string_literal: true

class ActivityGroupsController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_manage!

  def index
    @activity_group_templates = policy_scope(@story_group.activity_group_templates)
                                .includes(activity_groups: :activity_group_categories)
    @students = @story_group.student_memberships.with_user
    @completed = StudentActivityGroupCategory
                   .joins(activity_group_category: :activity_group)
                   .where(activity_groups: { story_group_id: @story_group.id })
                   .pluck(:activity_group_category_id, :student_id)
                   .to_set
  end

  def edit
    @activity_group = @story_group.activity_groups.find(params[:id])
  end

  def create
    template = @story_group.activity_group_templates.find(params.dig(:activity_group, :activity_group_template_id))
    name = params.dig(:activity_group, :name).presence || ActivityGroup.next_name_for_template(template)

    ActivityGroupBuilder.new(story_group: @story_group, template: template).build(name: name)

    redirect_to story_group_activity_groups_path(@story_group),
                notice: 'Activity group was successfully created.', status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    redirect_to story_group_activity_groups_path(@story_group),
                alert: e.message, status: :see_other
  end

  def update
    @activity_group = @story_group.activity_groups.find(params[:id])

    if @activity_group.update(activity_group_params)
      redirect_to story_group_activity_groups_path(@story_group),
                  notice: 'Activity group was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def create_bulk
    template = @story_group.activity_group_templates.find(params[:template_id])
    count = params[:count].to_i.clamp(1, 50)

    ActivityGroupBuilder.new(story_group: @story_group, template: template).build_many(count: count)

    redirect_to story_group_activity_groups_path(@story_group),
                notice: "#{count} activity group(s) created successfully.", status: :see_other
  end

  def save_completions
    @activity_group = @story_group.activity_groups.find(params[:id])
    categories = @activity_group.activity_group_categories.index_by(&:id)
    students = @story_group.student_memberships.index_by(&:id)

    new_set = build_completion_set(params[:completions])
    existing = StudentActivityGroupCategory
                 .where(activity_group_category_id: categories.keys)
                 .index_by { |c| [c.activity_group_category_id, c.student_id] }
    existing_set = existing.keys.to_set

    ActiveRecord::Base.transaction do
      (new_set - existing_set).each do |cat_id, student_id|
        next unless categories[cat_id] && students[student_id]

        StudentActivityGroupCategory.create!(
          activity_group_category_id: cat_id,
          student_id:                 student_id,
        )
        reward = categories[cat_id].reward
        students[student_id].increment!(:current_currency, reward)
        students[student_id].increment!(:total_currency, reward)
      end

      (existing_set - new_set).each do |cat_id, student_id|
        next unless existing[[cat_id, student_id]] && categories[cat_id] && students[student_id]

        existing[[cat_id, student_id]].destroy!
        reward = categories[cat_id].reward
        students[student_id].decrement!(:current_currency, reward)
        students[student_id].decrement!(:total_currency, reward)
      end
    end

    redirect_to story_group_activity_groups_path(@story_group),
                notice: 'Rewards saved.', status: :see_other
  end

  def destroy
    @activity_group = @story_group.activity_groups.find(params[:id])
    @activity_group.destroy!

    redirect_to story_group_activity_groups_path(@story_group),
                notice: 'Activity group was successfully destroyed.', status: :see_other
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def build_completion_set(completions_params)
    set = Set.new
    (completions_params || {}).each do |student_id, cat_hash|
      cat_hash.each_key { |cat_id| set.add([cat_id.to_i, student_id.to_i]) }
    end
    set
  end

  def activity_group_params
    params.expect(
      activity_group: [
        :name,
        {
          activity_group_categories_attributes: [%i[
            id story_description didactic_description reward position _destroy
          ]],
        },
      ],
    )
  end
end
