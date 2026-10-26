# frozen_string_literal: true

# One organization is linked to USOS logins: every USOS account lands in it,
# it has no member limit and cannot be deleted. An organization already named
# after the university keeps its members and becomes that organization.
class AddUsosToOrganizations < ActiveRecord::Migration[8.1]
  NAME = 'Uniwersytet im. Adama Mickiewicza w Poznaniu'
  LEGACY_NAME = 'Uniwersytet im. Adama Mickiewicza'

  def up
    add_column :organizations, :usos, :boolean, default: false, null: false
    add_index :organizations, :usos, unique: true, where: 'usos'

    execute <<~SQL.squish
      UPDATE organizations SET usos = TRUE, max_members = NULL, name = #{quote(NAME)}, updated_at = NOW()
      WHERE id = (SELECT id FROM organizations WHERE name IN (#{quote(NAME)}, #{quote(LEGACY_NAME)})
                  ORDER BY name = #{quote(NAME)} DESC LIMIT 1)
    SQL

    execute <<~SQL.squish
      INSERT INTO organizations (name, usos, max_members, created_at, updated_at)
      SELECT #{quote(NAME)}, TRUE, NULL, NOW(), NOW()
      WHERE NOT EXISTS (SELECT 1 FROM organizations WHERE usos)
    SQL
  end

  def down
    remove_index :organizations, :usos
    remove_column :organizations, :usos
  end

  private

  def quote(value) = connection.quote(value)
end
