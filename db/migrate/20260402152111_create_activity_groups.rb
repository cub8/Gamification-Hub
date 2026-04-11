# frozen_string_literal: true

class CreateActivityGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_groups do |t|
      t.references :story_group, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
