# frozen_string_literal: true

class CreateRanks < ActiveRecord::Migration[8.1]
  def change
    create_table :ranks do |t|
      t.references :story_group, null: false, foreign_key: true
      t.string :name
      t.integer :discount
      t.integer :required_currency_value
      t.timestamps
    end
  end
end
