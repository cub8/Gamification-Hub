# frozen_string_literal: true

module StoryGroupAuthorization
  def authorize_story_group_read!
    authorize @story_group, :show?
  end

  def authorize_story_group_manage!
    authorize @story_group, :update?
  end
end
