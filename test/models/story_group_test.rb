# frozen_string_literal: true

require 'test_helper'

class StoryGroupTest < ActiveSupport::TestCase
  test 'name too long' do
    story_group = StoryGroup.new(name:          'My name is extremely long and most likely, or atleast i
                                  hope it will not pass this test',
                                 description:   'Just a regular description',
                                 currency_name: 'Polski złoty',)

    assert_equal true, story_group.invalid?
    assert_equal true, story_group.errors[:name].any?
  end
end
