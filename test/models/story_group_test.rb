# frozen_string_literal: true

require 'test_helper'

class StoryGroupTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test 'name too long' do
    story_group = StoryGroup.new(name:          'My name is extremely long and most likely, or atleast i
                                  hope it will not pass this test',
                                 description:   'Just a regular description',
                                 currency_name: 'Polski złoty',)

    assert story_group.invalid?
    assert story_group.errors[:name].any?
  end
end
