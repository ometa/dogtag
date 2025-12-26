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

ActiveRecord::Schema[7.0].define(version: 2025_12_09_125509) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "classy_cache_org_members", force: :cascade do |t|
    t.integer "classy_org_id"
    t.string "email"
    t.integer "classy_member_id"
    t.datetime "classy_updated_at", precision: nil
    t.index ["email", "classy_member_id", "classy_updated_at"], name: "index_classy_org_members", unique: true
  end

  create_table "completed_requirements", id: :serial, force: :cascade do |t|
    t.integer "team_id"
    t.integer "requirement_id"
    t.integer "user_id"
    t.text "metadata"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["team_id", "requirement_id"], name: "index_completed_requirements_on_team_id_and_requirement_id", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "stripe_customer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_customer_id"], name: "index_customers_on_stripe_customer_id", unique: true
    t.index ["user_id"], name: "index_customers_on_user_id", unique: true
  end

  create_table "people", id: :serial, force: :cascade do |t|
    t.string "first_name", limit: 255
    t.string "last_name", limit: 255
    t.string "email", limit: 255
    t.string "phone", limit: 255
    t.string "twitter", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "team_id"
    t.integer "experience"
    t.string "zipcode", limit: 255, null: false
  end

  create_table "races", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "race_datetime", precision: nil
    t.datetime "registration_open", precision: nil
    t.datetime "registration_close", precision: nil
    t.integer "max_teams"
    t.integer "people_per_team"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "jsonform"
    t.string "filter_field", limit: 255
    t.integer "classy_campaign_id"
    t.integer "classy_default_goal"
    t.datetime "final_edits_close", precision: nil, null: false
  end

  create_table "requirements", id: :serial, force: :cascade do |t|
    t.integer "race_id"
    t.string "type", limit: 255
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "teams", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "description"
    t.string "twitter", limit: 255
    t.datetime "notified_at", precision: nil
    t.integer "race_id"
    t.integer "experience"
    t.string "buddies", limit: 255
    t.string "wildcard", limit: 255
    t.text "private_comments"
    t.text "jsonform"
    t.boolean "finalized"
    t.integer "assigned_team_number"
    t.string "classy_id"
    t.integer "classy_fundraiser_page_id"
    t.index ["race_id"], name: "index_teams_on_race_id"
  end

  create_table "tiers", id: :serial, force: :cascade do |t|
    t.integer "requirement_id"
    t.datetime "begin_at", precision: nil
    t.integer "price"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "first_name", limit: 255
    t.string "last_name", limit: 255
    t.string "phone", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "email", limit: 255, default: "", null: false
    t.string "crypted_password", limit: 255, default: "", null: false
    t.string "password_salt", limit: 255, default: "", null: false
    t.string "persistence_token", limit: 255, default: "", null: false
    t.string "single_access_token", limit: 255, default: "", null: false
    t.string "perishable_token", limit: 255, default: "", null: false
    t.integer "login_count", default: 0, null: false
    t.integer "failed_login_count", default: 0, null: false
    t.datetime "last_request_at", precision: nil
    t.datetime "current_login_at", precision: nil
    t.datetime "last_login_at", precision: nil
    t.string "current_login_ip", limit: 255
    t.string "last_login_ip", limit: 255
    t.string "stripe_customer_id", limit: 255
    t.integer "roles_mask"
    t.integer "classy_id"
  end

end
