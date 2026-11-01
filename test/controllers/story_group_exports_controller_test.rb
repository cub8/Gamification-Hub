# frozen_string_literal: true

require 'test_helper'

class StoryGroupExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher)
    sign_in @teacher
  end

  test 'show opts out of Turbo page caching so stale checkbox state is never flashed on return' do
    get story_group_export_url(@story_group)

    assert_response :success
    assert_select 'meta[name=turbo-cache-control][content=no-cache]'
  end

  test 'show renders an unchecked checkbox per resource, wired for the csv-export controller' do
    get story_group_export_url(@story_group)

    assert_response :success
    assert_select 'form[data-controller=csv-export]' do
      %w[ranks badges items templates].each do |resource|
        assert_select 'input[type=checkbox][name=?][value=?][data-csv-export-target=checkbox]' \
                      '[data-resource=?]', 'resources[]', resource, resource
        assert_select "input[value=#{resource}][checked]", false
      end

      assert_select 'button[type=submit][disabled]'
    end
  end

  test 'download returns a utf-8-bom-prefixed csv file for a valid resource' do
    FactoryBot.create(:rank, story_group: @story_group, name: 'Złoto')

    get download_story_group_export_url(@story_group, resource: 'ranks')

    assert_response :success
    assert_match %r{text/csv}, response.content_type
    assert_match(/attachment.*filename="ranks\.csv"/, response.headers['Content-Disposition'])
    assert_match(/\A﻿nazwa,/, response.body)
  end

  test 'download rejects an unknown resource' do
    get download_story_group_export_url(@story_group, resource: 'students')

    assert_response :bad_request
  end

  test 'should not export for story group not owned by teacher' do
    other_teacher = FactoryBot.create(:user, role: :teacher)
    other_story_group = FactoryBot.create(:story_group, owner: other_teacher)

    get story_group_export_url(other_story_group)

    assert_redirected_to root_url
  end

  test 'should not export without authentication' do
    sign_out

    get story_group_export_url(@story_group)

    assert_redirected_to login_url
  end
end
