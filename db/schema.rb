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

ActiveRecord::Schema[8.1].define(version: 2026_04_26_012127) do
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
    t.bigint "activity_group_template_id"
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "story_group_id", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_group_template_id"], name: "index_activity_groups_on_activity_group_template_id"
    t.index ["story_group_id"], name: "index_activity_groups_on_story_group_id"
  end

  create_table "badges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "didactic_description"
    t.integer "discount", default: 0
    t.string "name"
    t.text "story_description"
    t.bigint "story_group_id", null: false
    t.datetime "updated_at", null: false
    t.index ["story_group_id"], name: "index_badges_on_story_group_id"
  end

  create_table "currency_transactions", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.bigint "granted_by_user_id"
    t.integer "kind", null: false
    t.bigint "student_id", null: false
    t.bigint "transactionable_id", null: false
    t.string "transactionable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["granted_by_user_id"], name: "index_currency_transactions_on_granted_by_user_id"
    t.index ["student_id"], name: "index_currency_transactions_on_student_id"
    t.index ["transactionable_type", "transactionable_id"], name: "index_currency_transactions_on_transactionable"
  end

  create_table "items", force: :cascade do |t|
    t.boolean "can_buy_at_0_lives"
    t.datetime "created_at", null: false
    t.text "didactic_description"
    t.bigint "min_rank_for_discount_id"
    t.string "name"
    t.integer "price"
    t.text "story_description"
    t.bigint "story_group_id", null: false
    t.bigint "unlock_rank_id"
    t.datetime "updated_at", null: false
    t.index ["min_rank_for_discount_id"], name: "index_items_on_min_rank_for_discount_id"
    t.index ["story_group_id"], name: "index_items_on_story_group_id"
    t.index ["unlock_rank_id"], name: "index_items_on_unlock_rank_id"
  end

  create_table "items_min_badges_for_discounts", force: :cascade do |t|
    t.bigint "badge_id", null: false
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["badge_id"], name: "index_items_min_badges_for_discounts_on_badge_id"
    t.index ["item_id"], name: "index_items_min_badges_for_discounts_on_item_id"
  end

  create_table "items_unlock_badges", force: :cascade do |t|
    t.bigint "badge_id", null: false
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["badge_id"], name: "index_items_unlock_badges_on_badge_id"
    t.index ["item_id"], name: "index_items_unlock_badges_on_item_id"
  end

  create_table "login_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "token_digest"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["token_digest"], name: "index_login_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_login_tokens_on_user_id"
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
    t.integer "lives"
    t.integer "story_group_id"
    t.integer "total_currency", default: 0
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id", "story_group_id"], name: "index_story_group_students_on_user_id_and_story_group_id", unique: true
  end

  create_table "story_group_teachers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "story_group_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id", "story_group_id"], name: "index_story_group_teachers_on_user_id_and_story_group_id", unique: true
  end

  create_table "story_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency_name"
    t.integer "default_lives", default: 3
    t.text "description"
    t.string "name"
    t.integer "owner_id"
    t.datetime "updated_at", null: false
  end

  create_table "students_activity_group_categories", force: :cascade do |t|
    t.bigint "activity_group_category_id", null: false
    t.datetime "created_at", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_group_category_id"], name: "idx_on_activity_group_category_id_f3aa56fe63"
    t.index ["student_id", "activity_group_category_id"], name: "index_student_activity_group_categories_unique", unique: true
    t.index ["student_id"], name: "index_students_activity_group_categories_on_student_id"
  end

  create_table "students_badges", force: :cascade do |t|
    t.bigint "badge_id", null: false
    t.datetime "created_at", null: false
    t.bigint "story_group_student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["badge_id"], name: "index_students_badges_on_badge_id"
    t.index ["story_group_student_id"], name: "index_students_badges_on_story_group_student_id"
  end

  create_table "students_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "discount_applied", default: 0
    t.bigint "item_id", null: false
    t.integer "price_paid"
    t.bigint "story_group_student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_students_items_on_item_id"
    t.index ["story_group_student_id"], name: "index_students_items_on_story_group_student_id"
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
  add_foreign_key "activity_groups", "activity_group_templates"
  add_foreign_key "activity_groups", "story_groups"
  add_foreign_key "badges", "story_groups"
  add_foreign_key "currency_transactions", "story_group_students", column: "student_id"
  add_foreign_key "currency_transactions", "users", column: "granted_by_user_id"
  add_foreign_key "items", "ranks", column: "min_rank_for_discount_id"
  add_foreign_key "items", "ranks", column: "unlock_rank_id"
  add_foreign_key "items", "story_groups"
  add_foreign_key "items_min_badges_for_discounts", "badges"
  add_foreign_key "items_min_badges_for_discounts", "items"
  add_foreign_key "items_unlock_badges", "badges"
  add_foreign_key "items_unlock_badges", "items"
  add_foreign_key "login_tokens", "users"
  add_foreign_key "ranks", "story_groups"
  add_foreign_key "students_activity_group_categories", "activity_group_categories"
  add_foreign_key "students_activity_group_categories", "story_group_students", column: "student_id"
  add_foreign_key "students_badges", "badges"
  add_foreign_key "students_badges", "story_group_students"
  add_foreign_key "students_items", "items"
  add_foreign_key "students_items", "story_group_students"
end
