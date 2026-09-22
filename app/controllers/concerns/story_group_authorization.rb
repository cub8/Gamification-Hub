# frozen_string_literal: true

module StoryGroupAuthorization
  def authorize_story_group_read!
    authorize @story_group, :show?
  end

  def authorize_story_group_manage!
    authorize @story_group, :update?
  end

  # Stricter than #manage: running a group and deciding who else runs it are
  # different questions, and only the owner answers the second one.
  def authorize_story_group_teachers!
    authorize @story_group, :manage_teachers?
  end
end
