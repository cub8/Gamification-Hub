# frozen_string_literal: true

class CreateStoryGroupTeachers < ActiveRecord::Migration[8.1]
  def change
    create_table :story_group_teachers do |t|
      t.integer :user_id
      t.integer :story_group_id

      t.timestamps
    end
  end
end
