# frozen_string_literal: true

require 'test_helper'

class SessionUserBuilderTest < ActiveSupport::TestCase
  class TestAdapter < Providers::BaseAdapter
    private

    def build_params
      @full_name = @auth[:full_name]
      @email = @auth[:email]
      @role = @auth[:role]
      @university_name = @auth[:university_name]
      @university_number = @auth[:university_number]
      @usos_id = @auth[:usos_id]
    end
  end

  setup do
    @provider = TestAdapter.new(
      {
        full_name:         'Jan Nowak',
        email:             'jan.nowak@gmail.com',
        role:              'student',
        university_name:   'Example university',
        university_number: '123456',
        usos_id:           '123456',
      },
    )
  end

  test 'new user joins the USOS organization' do
    assert_difference 'User.count', 1 do
      user = SessionUserBuilder.new(@provider).build

      assert_equal 'jan.nowak@gmail.com', user.email
      assert_equal Organization.usos, user.organization
    end
  end

  test 'the USOS organization is created on first login if missing' do
    assert_difference -> { Organization.where(usos: true).count }, 1 do
      SessionUserBuilder.new(@provider).build
    end

    second = TestAdapter.new({ email: 'anna@example.com', full_name: 'Anna Nowak', role: 'student' })
    assert_no_difference 'Organization.count' do
      SessionUserBuilder.new(second).build
    end
  end

  test 'existing student keeps their organization' do
    other = FactoryBot.create(:organization, max_members: 5)
    user = FactoryBot.create(:user, :student, email: 'jan.nowak@gmail.com', organization: other)

    SessionUserBuilder.new(@provider).build

    assert_equal other, user.reload.organization
  end

  test 'existing student without an organization joins the USOS organization' do
    user = FactoryBot.create(:user, :student, email: 'jan.nowak@gmail.com', organization: nil)

    SessionUserBuilder.new(@provider).build

    assert_equal Organization.usos, user.reload.organization
  end

  test 'organization admin keeps their organization' do
    other = FactoryBot.create(:organization, max_members: 5)
    admin = FactoryBot.create(:user, :organization_admin, email: 'jan.nowak@gmail.com', organization: other)

    SessionUserBuilder.new(@provider).build

    assert_equal other, admin.reload.organization
  end

  test 'do not create new user if user exists' do
    original_user = FactoryBot.create(:user, email: 'jan.nowak@gmail.com')

    assert_no_difference 'User.count' do
      user = SessionUserBuilder.new(@provider).build
      assert_equal original_user.id, user.id
    end
  end

  test 'update user if user exists, but first_login is true' do
    user = FactoryBot.create(:user, first_login: true, email: nil, usos_id: '123456',
university_name: 'Example university',)
    SessionUserBuilder.new(@provider).build

    assert_equal 'jan.nowak@gmail.com', user.reload.email
  end

  test 'raise an error if no usos_id or email in provider' do
    provider = TestAdapter.new(
      {
        full_name:       'Jan Nowak',
        role:            'student',
        university_name: 'Example university',
      },
    )

    assert_raises Providers::InvalidAuthError do
      SessionUserBuilder.new(provider).build
    end
  end
end
