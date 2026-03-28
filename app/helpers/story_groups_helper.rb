# frozen_string_literal: true

module StoryGroupsHelper
  def has_access_to_story_groups(current_user)
    current_user.teacher? || current_user.organization_admin? || current_user.global_admin?
  end
end
