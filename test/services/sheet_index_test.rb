# frozen_string_literal: true

require 'test_helper'

class SheetIndexTest < ActiveSupport::TestCase
  setup do
    @story_group = create(:story_group)
  end

  test 'keeps a deleted template listed while it still has sheets' do
    template = create(:activity_group_template, story_group: @story_group)
    create(:activity_group, story_group: @story_group, activity_group_template: template)
    template.soft_delete!

    listed = SheetIndex.new(@story_group).templates.sole

    assert_equal template, listed.record
    assert_predicate listed, :deleted?
    assert_equal 1, listed.sheets.size
  end

  test 'drops a deleted template without sheets' do
    create(:activity_group_template, story_group: @story_group).soft_delete!

    assert_empty SheetIndex.new(@story_group).templates
  end

  test 'drops a deleted template whose sheets are deleted too' do
    template = create(:activity_group_template, story_group: @story_group)
    create(:activity_group, story_group: @story_group, activity_group_template: template).soft_delete!
    template.soft_delete!

    assert_empty SheetIndex.new(@story_group).templates
  end
end
