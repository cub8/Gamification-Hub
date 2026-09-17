# frozen_string_literal: true

class AddNicknameToStoryGroupStudents < ActiveRecord::Migration[8.1]
  def change
    add_column :story_group_students, :nickname, :string

    # Nicknames are unique per group, case-insensitively (DECISIONS.md), but
    # they are optional: a blank one means "use my real name". Hence a partial
    # functional index rather than a plain unique one — several memberships in
    # the same group may legitimately have no nickname at all.
    add_index :story_group_students, 'story_group_id, lower(nickname)',
              unique: true,
              where:  'nickname IS NOT NULL',
              name:   'index_story_group_students_on_group_and_lower_nickname'
  end
end
