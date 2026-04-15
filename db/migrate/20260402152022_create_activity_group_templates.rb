# frozen_string_literal: true

class CreateActivityGroupTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_group_templates do |t|
      t.references :story_group, null: false, foreign_key: true
      t.string :base_name

      t.timestamps
    end
  end
end
