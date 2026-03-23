class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :name
      t.text :story_description
      t.text :didactic_description

      t.references :story_group, null: false, foreign_key: true

      t.integer :min_rank_for_discount_id
      t.integer :unlock_rank_id

      t.timestamps
    end
  end
end