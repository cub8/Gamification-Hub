# frozen_string_literal: true

class AddFieldsToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :can_buy_at_0_lives, :boolean
  end
end
