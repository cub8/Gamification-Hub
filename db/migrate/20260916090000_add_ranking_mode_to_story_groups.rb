# frozen_string_literal: true

class AddRankingModeToStoryGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :story_groups, :ranking_mode, :integer, default: 0, null: false
  end
end
