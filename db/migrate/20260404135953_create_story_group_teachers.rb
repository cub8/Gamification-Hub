# frozen_string_literal: true

class CreateStoryGroupTeachers < ActiveRecord::Migration[8.1]
  def change
    create_table :story_group_teachers do |t|
      t.integer :user_id
      t.integer :story_group_id

      t.timestamps
    end
    add_index :story_group_teachers, %i[user_id story_group_id], unique: true
  end
end
