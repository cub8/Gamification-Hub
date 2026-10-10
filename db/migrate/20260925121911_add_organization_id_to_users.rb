# frozen_string_literal: true

class AddOrganizationIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :organization, foreign_key: true
  end
end
