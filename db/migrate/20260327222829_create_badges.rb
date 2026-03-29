class CreateBadges < ActiveRecord::Migration[8.1]
  def change
    create_table :badges do |t|
      t.references :story_group, null: false, foreign_key: true
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
