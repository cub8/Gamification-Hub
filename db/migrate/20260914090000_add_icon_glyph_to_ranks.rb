# frozen_string_literal: true

class AddIconGlyphToRanks < ActiveRecord::Migration[8.1]
  def change
    add_column :ranks, :icon_glyph, :string

    add_index :ranks, %i[story_group_id required_currency_value], unique: true,
                                                                  name:   'index_ranks_on_group_and_threshold'
  end
end
