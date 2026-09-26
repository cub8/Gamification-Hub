# frozen_string_literal: true

class AddGlyphAndSoftDeleteToBadges < ActiveRecord::Migration[8.1]
  def change
    add_column :badges, :icon_glyph, :string

    add_column :badges, :deleted_at, :datetime
    add_index :badges, %i[story_group_id deleted_at]
  end
end
