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

  test 'create new user if no user in database' do
    organization = FactoryBot.create(:organization, name: 'Example university')

    assert_difference 'User.count', 1 do
      user = SessionUserBuilder.new(@provider).build

      assert_equal 'jan.nowak@gmail.com', user.email
      assert_equal organization, user.organization
    end
  end

  test 'do not create new user if no organization matches university name' do
    FactoryBot.create(:organization, name: 'Other university')

    assert_no_difference 'User.count' do
      assert_raises SessionUserBuilder::OrganizationNotFoundError do
        SessionUserBuilder.new(@provider).build
      end
    end
  end

  test 'do not create new user if organization is full' do
    organization = FactoryBot.create(:organization, name: 'Example university', max_members: 1)
    FactoryBot.create(:user, organization: organization)

    assert_no_difference 'User.count' do
      assert_raises SessionUserBuilder::OrganizationFullError do
        SessionUserBuilder.new(@provider).build
      end
    end
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
