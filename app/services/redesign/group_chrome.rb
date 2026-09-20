# frozen_string_literal: true

module Redesign
  # "Which group am I in, and what am I to it?" — the one question the in-group
  # chrome asks (mockup `inGroup()`, js-expanded/10-core.js:153).
  #
  # It resolves a membership and reads a policy, so it queries: services, not
  # values. The nav item lists themselves stay in Redesign::Navigation.
  class GroupChrome
    ROLE_LABELS = {
      own: 'Prowadzisz tę grupę',
      sup: 'Wspierasz tę grupę',
      lrn: 'Jesteś uczestnikiem',
    }.freeze

    attr_reader :user, :story_group, :student_membership

    class << self
      # nil unless the user actually belongs to this group.
      #
      # This is what keeps the join flow safe: JoinController sets @story_group
      # from an invite lookup for somebody who is not in the group yet. Leaning
      # on @story_group merely being absent there would be luck; belonging is
      # the rule.
      def for(user:, story_group:)
        return if user.nil? || story_group.nil?
        # An UNSAVED group is not a group you are in. StoryGroupsController
        # builds one for the creation wizard and re-renders it on a validation
        # failure, with owner_id already assigned — so `member?` would say yes
        # and every nav link would then ask for a path to a record with no id.
        return unless story_group.persisted?

        chrome = new(user: user, story_group: story_group)

        chrome if chrome.member?
      end
    end

    def initialize(user:, story_group:)
      @user = user
      @story_group = story_group
      @student_membership = story_group.student_memberships.find_by(user: user)
    end

    # Membership decides the persona, NOT user.teacher? and not the policy.
    # Shared::MainSidebarComponent#story_group_student? and
    # StoryGroupsController#show already branch this way, so the nav and the
    # dashboard rendered beside it cannot disagree about who you are here.
    def student? = student_membership.present?

    def member? = student? || owner? || supporting_teacher?

    def name = story_group.name

    def role_label = ROLE_LABELS[role]

    def role
      return :lrn if student?
      return :own if owner?

      :sup
    end

    def items = navigation.group_items(self)

    def tab_items = navigation.group_tab_items(self)

    # The mockup shows Ranking unconditionally; ours honours the same rule the
    # ranking screen itself enforces, rather than re-deriving `ranking_enabled`
    # the way the Bootstrap sidebar does.
    def ranking?
      return @ranking unless @ranking.nil?

      @ranking = StoryGroupPolicy.new(user, story_group).view_ranking?
    end

    private

    def navigation = @navigation ||= Navigation.new(user)

    def owner? = story_group.owner_id == user.id

    def supporting_teacher? = story_group.teachers.include?(user)
  end
end
