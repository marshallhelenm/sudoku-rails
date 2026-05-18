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

ActiveRecord::Schema[8.1].define(version: 5) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "goal_habits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "goal_id", null: false
    t.bigint "habit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["goal_id"], name: "index_goal_habits_on_goal_id"
    t.index ["habit_id"], name: "index_goal_habits_on_habit_id"
  end

  create_table "goals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "daily_earnings_cap"
    t.string "name"
    t.float "target_amount"
    t.float "total_saved"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "habit_saver_auth_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.datetime "last_seen_at", null: false
    t.datetime "revoked_at"
    t.string "session_token_digest", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_habit_saver_auth_sessions_on_expires_at"
    t.index ["session_token_digest"], name: "index_habit_saver_auth_sessions_on_session_token_digest", unique: true
    t.index ["user_id"], name: "index_habit_saver_auth_sessions_on_user_id"
  end

  create_table "habit_saver_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_habit_saver_users_on_email", unique: true
  end

  create_table "habits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_streak", default: 0, null: false
    t.datetime "last_day"
    t.string "name"
    t.integer "streak_record", default: 0, null: false
    t.integer "tally", default: 0, null: false
    t.integer "target_per_unit", default: 1, null: false
    t.string "time_unit", default: "day", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_habits_on_user_id"
  end

  add_foreign_key "goal_habits", "goals"
  add_foreign_key "goal_habits", "habits"
  add_foreign_key "goals", "habit_saver_users", column: "user_id"
  add_foreign_key "habit_saver_auth_sessions", "habit_saver_users", column: "user_id"
  add_foreign_key "habits", "habit_saver_users", column: "user_id"
end
