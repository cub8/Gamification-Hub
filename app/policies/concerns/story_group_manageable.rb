# frozen_string_literal: true

module StoryGroupManageable
  private

  def can_manage_associated_story_group?
    story_group = extract_story_group
    can_manage_story_group?(story_group)
  end

  def can_manage_story_group?(story_group)
    StoryGroupPolicy.new(user, story_group).update?
  end

  def extract_story_group
    raise ArgumentError, "Cannot extract story_group from #{scope.inspect}" unless scope.respond_to?(:proxy_association)

    scope.proxy_association.owner
  end
end
