class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name
      t.integer :max_members

      t.timestamps
    end
  end
end
