class CreateStoryGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :story_groups do |t|
      t.integer :owner_id
      t.string :name
      t.text :description
      t.string :currency_name

      t.timestamps
    end
  end
end
