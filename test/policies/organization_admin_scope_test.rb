# frozen_string_literal: true

require 'test_helper'

class OrganizationAdminScopeTest < ActiveSupport::TestCase
  setup do
    @organization = FactoryBot.create(:organization, max_members: 10)
    @admin = FactoryBot.create(:user, :organization_admin, organization: @organization)
    @own_group = FactoryBot.create(:story_group, owner: FactoryBot.create(:user, :teacher, organization: @organization))

    other = FactoryBot.create(:organization, max_members: 10)
    @foreign_group = FactoryBot.create(:story_group, owner: FactoryBot.create(:user, :teacher, organization: other))
  end

  test 'manages groups in their own organization' do
    policy = StoryGroupPolicy.new(@admin, @own_group)

    assert policy.show?
    assert policy.update?
    assert policy.destroy?
  end

  test 'cannot reach groups in another organization' do
    policy = StoryGroupPolicy.new(@admin, @foreign_group)

    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.view_ranking?
  end

  test 'can still create groups' do
    assert StoryGroupPolicy.new(@admin, StoryGroup).create?
  end

  test 'manages students only in their own organization' do
    own = enroll(@own_group)
    foreign = enroll(@foreign_group)

    assert StoryGroupStudentPolicy.new(@admin, own).update?
    assert_not StoryGroupStudentPolicy.new(@admin, foreign).update?
    assert_equal [own], StoryGroupStudentPolicy::Scope.new(@admin, StoryGroupStudent).resolve.to_a
  end

  private

  def enroll(story_group)
    FactoryBot.create(:story_group_student, story_group: story_group, user: FactoryBot.create(:user, :student))
  end
end
