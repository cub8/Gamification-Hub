# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_02_152121) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_group_categories", force: :cascade do |t|
    t.bigint "activity_group_id", null: false
    t.datetime "created_at", null: false
    t.text "didactic_description"
    t.integer "position"
    t.integer "reward"
    t.text "story_description"
    t.datetime "updated_at", null: false
    t.index ["activity_group_id"], name: "index_activity_group_categories_on_activity_group_id"
  end

  create_table "activity_group_template_categories", force: :cascade do |t|
    t.bigint "activity_group_template_id", null: false
    t.datetime "created_at", null: false
    t.text "didactic_description"
    t.integer "position"
    t.integer "reward"
    t.text "story_description"
    t.datetime "updated_at", null: false
    t.index ["activity_group_template_id"], name: "idx_on_activity_group_template_id_500cd46a46"
  end

  create_table "activity_group_templates", force: :cascade do |t|
    t.string "base_name"
    t.datetime "created_at", null: false
    t.bigint "story_group_id", null: false
    t.datetime "updated_at", null: false
    t.index ["story_group_id"], name: "index_activity_group_templates_on_story_group_id"
  end

  create_table "activity_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "story_group_id", null: false
    t.datetime "updated_at", null: false
    t.index ["story_group_id"], name: "index_activity_groups_on_story_group_id"
  end

  create_table "badges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "discount", default: 0
    t.string "name"
    t.bigint "story_group_id", null: false
    t.datetime "updated_at", null: false
    t.index ["story_group_id"], name: "index_badges_on_story_group_id"
  end

  create_table "items", force: :cascade do |t|
    t.boolean "can_buy_at_0_lives"
    t.datetime "created_at", null: false
    t.text "didactic_description"
    t.string "name"
    t.integer "price"
    t.text "story_description"
    t.bigint "story_group_id", null: false
    t.datetime "updated_at", null: false
    t.index ["story_group_id"], name: "index_items_on_story_group_id"
  end

  create_table "ranks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "discount"
    t.string "name"
    t.integer "required_currency_value"
    t.bigint "story_group_id", null: false
    t.datetime "updated_at", null: false
    t.index ["story_group_id"], name: "index_ranks_on_story_group_id"
  end

  create_table "story_group_students", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_currency", default: 0
    t.integer "lives", default: 3
    t.integer "story_group_id"
    t.integer "total_currency", default: 0
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "story_group_teachers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "story_group_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "story_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency_name"
    t.text "description"
    t.string "name"
    t.integer "owner_id"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.boolean "first_login", default: true
    t.string "full_name"
    t.integer "role", default: 1
    t.string "university_name"
    t.string "university_number"
    t.datetime "updated_at", null: false
    t.string "usos_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["usos_id", "university_name"], name: "index_users_on_usos_id_and_university_name", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_group_categories", "activity_groups"
  add_foreign_key "activity_group_template_categories", "activity_group_templates"
  add_foreign_key "activity_group_templates", "story_groups"
  add_foreign_key "activity_groups", "story_groups"
  add_foreign_key "badges", "story_groups"
  add_foreign_key "items", "story_groups"
  add_foreign_key "ranks", "story_groups"
end
