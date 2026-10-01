# frozen_string_literal: true

class GroupChrome
  ROLE_LABELS = {
    own: 'Prowadzisz tę grupę',
    sup: 'Wspierasz tę grupę',
    lrn: 'Jesteś uczestnikiem',
  }.freeze

  attr_reader :user, :story_group, :student_membership

  class << self
    def for(user:, story_group:)
      return if user.nil? || story_group.nil?
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

  def ranking?
    return @ranking unless @ranking.nil?

    @ranking = StoryGroupPolicy.new(user, story_group).view_ranking?
  end

  private

  def navigation = @navigation ||= Navigation.new(user)

  def owner? = story_group.owner_id == user.id

  def supporting_teacher? = story_group.teachers.include?(user)
end
