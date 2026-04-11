# frozen_string_literal: true

class CreateActivityGroupCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_group_categories do |t|
      t.references :activity_group, null: false, foreign_key: true
      t.text :story_description
      t.text :didactic_description
      t.integer :reward
      t.integer :position

      t.timestamps
    end
  end
end
