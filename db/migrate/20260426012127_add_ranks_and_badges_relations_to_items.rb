# frozen_string_literal: true

class AddRanksAndBadgesRelationsToItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :items, :unlock_rank, foreign_key: { to_table: :ranks }, null: true
    add_reference :items, :min_rank_for_discount, foreign_key: { to_table: :ranks }, null: true

    create_table :items_unlock_badges do |t|
      t.references :item, null: false, foreign_key: true
      t.references :badge, null: false, foreign_key: true
      t.timestamps
    end

    create_table :items_min_badges_for_discounts do |t|
      t.references :item, null: false, foreign_key: true
      t.references :badge, null: false, foreign_key: true
      t.timestamps
    end

    create_table :students_items do |t|
      t.references :story_group_student, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :price_paid
      t.integer :discount_applied, default: 0
      t.timestamps
    end
  end
end
