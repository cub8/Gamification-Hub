# frozen_string_literal: true

class AddRankingEnabledToStoryGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :story_groups, :ranking_enabled, :boolean, default: false, null: false
  end
end
