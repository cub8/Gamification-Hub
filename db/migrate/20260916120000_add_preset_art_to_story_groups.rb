# frozen_string_literal: true

class AddPresetArtToStoryGroups < ActiveRecord::Migration[8.1]
  def change
    # The group's two images, the same way ranks, badges and items already hold
    # theirs: a key into a Redesign preset registry, with the artwork on disk
    # and never copied into the database. NULL means "use the upload instead",
    # so each pair says which of the two is the art:
    #
    #   NULL + attachment -> the upload
    #   key  + attachment -> the preset, upload kept so you can switch back
    #   key  + no upload  -> the preset
    #   NULL + no upload  -> neither; the monogram/initial fallback renders
    #
    # The last row is why neither column is NOT NULL: every group that exists
    # today has no art at all, and that is a legitimate state the cards already
    # draw for.

    # Redesign::GroupArt — the 160x90 cover on the group card, the sidebar deck
    # and the overview hero.
    add_column :story_groups, :icon_glyph, :string

    # Redesign::CurrencyIcons — the mark on the coin face, wherever an amount
    # in this group's currency is shown.
    add_column :story_groups, :currency_icon_glyph, :string
  end
end
