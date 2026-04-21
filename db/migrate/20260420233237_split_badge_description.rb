class SplitBadgeDescription < ActiveRecord::Migration[8.1]
def change
    rename_column :badges, :description, :story_description
    add_column :badges, :didactic_description, :text
  end
end
