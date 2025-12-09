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
  enable_extension "plpgsql"

  create_table "classy_cache_org_members", force: :cascade do |t|
    t.integer "classy_org_id"
    t.string "email"
    t.integer "classy_member_id"
    t.datetime "classy_updated_at", precision: nil
    t.index ["email", "classy_member_id", "classy_updated_at"], name: "index_classy_org_members", unique: true
  end

  create_table "completed_requirements", force: :cascade do |t|
    t.bigint "team_id"
    t.bigint "requirement_id"
    t.bigint "user_id"
    t.text "metadata"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["requirement_id"], name: "index_completed_requirements_on_requirement_id"
    t.index ["team_id", "requirement_id"], name: "index_completed_requirements_on_team_id_and_requirement_id", unique: true
    t.index ["team_id"], name: "index_completed_requirements_on_team_id"
    t.index ["user_id"], name: "index_completed_requirements_on_user_id"
  end

  create_table "customers", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "stripe_customer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_customer_id"], name: "index_customers_on_stripe_customer_id", unique: true
    t.index ["user_id"], name: "index_customers_on_user_id", unique: true
  end

  create_table "people", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.string "twitter"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "team_id"
    t.integer "experience"
    t.string "zipcode", null: false
    t.index ["team_id"], name: "index_people_on_team_id"
  end

  create_table "races", force: :cascade do |t|
    t.string "name"
    t.datetime "race_datetime", precision: nil
    t.datetime "registration_open", precision: nil
    t.datetime "registration_close", precision: nil
    t.integer "max_teams"
    t.integer "people_per_team"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "jsonform"
    t.string "filter_field"
    t.integer "classy_campaign_id"
    t.integer "classy_default_goal"
    t.datetime "final_edits_close", precision: nil, null: false
  end

  create_table "requirements", force: :cascade do |t|
    t.bigint "race_id"
    t.string "type"
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["race_id"], name: "index_requirements_on_race_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "description"
    t.string "twitter"
    t.datetime "notified_at", precision: nil
    t.integer "race_id"
    t.integer "experience"
    t.string "buddies"
    t.string "wildcard"
    t.text "private_comments"
    t.text "jsonform"
    t.boolean "finalized"
    t.integer "assigned_team_number"
    t.string "classy_id"
    t.integer "classy_fundraiser_page_id"
    t.index ["race_id"], name: "index_teams_on_race_id"
    t.index ["user_id"], name: "index_teams_on_user_id"
  end

  create_table "tiers", force: :cascade do |t|
    t.bigint "requirement_id"
    t.datetime "begin_at", precision: nil
    t.integer "price"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["requirement_id"], name: "index_tiers_on_requirement_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "email", default: "", null: false
    t.string "crypted_password", default: "", null: false
    t.string "password_salt", default: "", null: false
    t.string "persistence_token", default: "", null: false
    t.string "single_access_token", default: "", null: false
    t.string "perishable_token", default: "", null: false
    t.integer "login_count", default: 0, null: false
    t.integer "failed_login_count", default: 0, null: false
    t.datetime "last_request_at", precision: nil
    t.datetime "current_login_at", precision: nil
    t.datetime "last_login_at", precision: nil
    t.string "current_login_ip"
    t.string "last_login_ip"
    t.string "stripe_customer_id"
    t.integer "roles_mask"
    t.integer "classy_id"
  end

end
