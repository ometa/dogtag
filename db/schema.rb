# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20200107073519) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_stat_statements"

  create_table "completed_requirements", force: :cascade do |t|
    t.integer  "team_id"
    t.integer  "requirement_id"
    t.integer  "user_id"
    t.text     "metadata"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "completed_requirements", ["team_id", "requirement_id"], name: "index_completed_requirements_on_team_id_and_requirement_id", unique: true, using: :btree

  create_table "people", force: :cascade do |t|
    t.string   "first_name", limit: 255
    t.string   "last_name",  limit: 255
    t.string   "email",      limit: 255
    t.string   "phone",      limit: 255
    t.string   "twitter",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "team_id"
    t.integer  "experience"
    t.string   "zipcode",    limit: 255, null: false
  end

  create_table "races", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.datetime "race_datetime"
    t.datetime "registration_open"
    t.datetime "registration_close"
    t.integer  "max_teams"
    t.integer  "people_per_team"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "jsonform"
    t.string   "filter_field",        limit: 255
    t.integer  "classy_campaign_id"
    t.integer  "classy_default_goal"
    t.datetime "final_edits_close",               null: false
  end

  create_table "requirements", force: :cascade do |t|
    t.integer  "race_id"
    t.string   "type",       limit: 255
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "teams", force: :cascade do |t|
    t.string   "name",                      limit: 255
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.string   "twitter",                   limit: 255
    t.datetime "notified_at"
    t.integer  "race_id"
    t.integer  "experience"
    t.string   "buddies",                   limit: 255
    t.string   "wildcard",                  limit: 255
    t.text     "private_comments"
    t.text     "jsonform"
    t.boolean  "finalized"
    t.integer  "assigned_team_number"
    t.integer  "classy_id"
    t.integer  "classy_fundraiser_page_id"
    t.integer  "style",                                 default: 0, null: false
  end

  add_index "teams", ["race_id"], name: "index_teams_on_race_id", using: :btree

  create_table "tiers", force: :cascade do |t|
    t.integer  "requirement_id"
    t.datetime "begin_at"
    t.integer  "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "first_name",          limit: 255
    t.string   "last_name",           limit: 255
    t.string   "phone",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",               limit: 255, default: "", null: false
    t.string   "crypted_password",    limit: 255, default: "", null: false
    t.string   "password_salt",       limit: 255, default: "", null: false
    t.string   "persistence_token",   limit: 255, default: "", null: false
    t.string   "single_access_token", limit: 255, default: "", null: false
    t.string   "perishable_token",    limit: 255, default: "", null: false
    t.integer  "login_count",                     default: 0,  null: false
    t.integer  "failed_login_count",              default: 0,  null: false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip",    limit: 255
    t.string   "last_login_ip",       limit: 255
    t.string   "stripe_customer_id",  limit: 255
    t.integer  "roles_mask"
    t.integer  "classy_id"
  end

end
