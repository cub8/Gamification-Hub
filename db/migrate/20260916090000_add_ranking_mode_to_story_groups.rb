# frozen_string_literal: true

class AddRankingModeToStoryGroups < ActiveRecord::Migration[8.1]
  def change
    # How much of the ranking a STUDENT is allowed to see once
    # `ranking_enabled` is on (DECISIONS.md:36). The flag says whether there is
    # a ranking at all; this says who appears in it:
    #
    #   0 podium_and_own -> the top three, plus your own place
    #   1 full           -> everyone, in order
    #
    # Default 0, because the safer of the two is the one a new group should get
    # without anybody choosing it. Teachers always see the whole list, so this
    # column never narrows what they read.
    add_column :story_groups, :ranking_mode, :integer, default: 0, null: false
  end
end
