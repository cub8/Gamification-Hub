# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'normalizes e-mail' do
    user = User.new(email: '   SIEMA@gmail.com   ')
    user.save!

    assert_equal 'siema@gmail.com', user.email
  end

  test 'cannot join a full organization' do
    organization = FactoryBot.create(:organization, max_members: 1)
    FactoryBot.create(:user, organization: organization)

    user = FactoryBot.build(:user, organization: organization)
    assert_not user.valid?
    assert user.errors.added?(:organization, :member_limit)
  end

  test 'existing member can be updated in a full organization' do
    organization = FactoryBot.create(:organization, max_members: 1)
    user = FactoryBot.create(:user, organization: organization)

    assert user.update(full_name: 'Nowe Imię')
  end

  test 'invited user can only be a student or teacher' do
    assert FactoryBot.build(:user, role: :student).valid?(:user_invitation)
    assert FactoryBot.build(:user, role: :teacher).valid?(:user_invitation)

    user = FactoryBot.build(:user, role: :global_admin)
    assert_not user.valid?(:user_invitation)
    assert user.errors[:role].any?
  end

  test 'destroying an owner removes their groups with everything in them' do
    owner = FactoryBot.create(:user, :teacher)
    story_group = FactoryBot.create(:story_group, owner: owner)
    student = FactoryBot.create(:story_group_student, story_group: story_group,
                                                      user:        FactoryBot.create(:user, :student),)
    item = FactoryBot.create(:item, story_group: story_group)
    FactoryBot.create(:students_item, story_group_student: student, item: item)
    FactoryBot.create(:currency_transaction, student: student, kind: :purchase, transactionable: item)
    FactoryBot.create(:notification, user: owner, story_group: story_group, story_group_student: student, item: item)
    template = FactoryBot.create(:activity_group_template, story_group: story_group)
    FactoryBot.create(:activity_group, story_group: story_group, activity_group_template: template)

    owner.destroy!

    assert_not StoryGroup.exists?(story_group.id)
    assert_not StoryGroupStudent.exists?(student.id)
    assert student.user.reload, 'the student account itself stays'
  end
end
