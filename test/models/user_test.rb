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
    assert_includes user.errors[:organization], 'has reached its member limit'
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
end
