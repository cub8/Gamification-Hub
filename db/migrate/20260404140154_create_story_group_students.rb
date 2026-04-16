# frozen_string_literal: true

class CreateStoryGroupStudents < ActiveRecord::Migration[8.1]
  def change
    create_table :story_group_students do |t|
      t.integer :user_id
      t.integer :story_group_id
      t.integer :lives, default: 3
      t.integer :current_currency, default: 0
      t.integer :total_currency, default: 0

      t.timestamps
    end
    add_index :story_group_students, %i[user_id story_group_id], unique: true
  end
end
