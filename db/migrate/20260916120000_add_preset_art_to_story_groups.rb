# frozen_string_literal: true

class AddPresetArtToStoryGroups < ActiveRecord::Migration[8.1]
  def change

    add_column :story_groups, :icon_glyph, :string

    add_column :story_groups, :currency_icon_glyph, :string
  end
end
