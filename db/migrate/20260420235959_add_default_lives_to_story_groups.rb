class AddDefaultLivesToStoryGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :story_groups, :default_lives, :integer, default: 3
  end
end
