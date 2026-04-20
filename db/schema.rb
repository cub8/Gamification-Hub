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

ActiveRecord::Schema[8.1].define(version: 2026_04_20_153517) do
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

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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

  create_table "story_group_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "story_group_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["story_group_id"], name: "index_story_group_users_on_story_group_id"
    t.index ["user_id"], name: "index_story_group_users_on_user_id"
  end

  create_table "story_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency_name"
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
  add_foreign_key "activity_groups", "activity_group_templates"
  add_foreign_key "badges", "story_groups"
  add_foreign_key "items", "story_groups"
  add_foreign_key "login_tokens", "users"
  add_foreign_key "ranks", "story_groups"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "story_group_users", "story_groups"
  add_foreign_key "story_group_users", "users"
  add_foreign_key "students_activity_group_categories", "activity_group_categories"
  add_foreign_key "students_activity_group_categories", "story_group_students", column: "student_id"
end
