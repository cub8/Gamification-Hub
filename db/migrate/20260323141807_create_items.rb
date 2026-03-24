# frozen_string_literal: true

class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :name
      t.text :story_description
      t.text :didactic_description
      t.integer :price
      t.references :story_group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
