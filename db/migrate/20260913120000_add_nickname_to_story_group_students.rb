# frozen_string_literal: true

class AddNicknameToStoryGroupStudents < ActiveRecord::Migration[8.1]
  def change
    add_column :story_group_students, :nickname, :string

    add_index :story_group_students, 'story_group_id, lower(nickname)',
              unique: true,
              where:  'nickname IS NOT NULL',
              name:   'index_story_group_students_on_group_and_lower_nickname'
  end
end
