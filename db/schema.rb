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

ActiveRecord::Schema.define(version: 20160115052426) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "phone"
    t.string   "twitter"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "team_id"
    t.integer  "experience"
    t.string   "zipcode",    null: false
  end

  create_table "races", force: :cascade do |t|
    t.string   "name"
    t.datetime "race_datetime"
    t.datetime "registration_open"
    t.datetime "registration_close"
    t.integer  "max_teams"
    t.integer  "people_per_team"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "jsonform"
    t.string   "filter_field"
  end

  create_table "requirements", force: :cascade do |t|
    t.integer  "race_id"
    t.string   "type"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "teams", force: :cascade do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.string   "twitter"
    t.datetime "notified_at"
    t.integer  "race_id"
    t.integer  "experience"
    t.string   "buddies"
    t.string   "wildcard"
    t.text     "private_comments"
    t.text     "jsonform"
    t.boolean  "finalized"
    t.integer  "assigned_team_number"
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
    t.string   "first_name"
    t.string   "last_name"
    t.string   "phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",               default: "", null: false
    t.string   "crypted_password",    default: "", null: false
    t.string   "password_salt",       default: "", null: false
    t.string   "persistence_token",   default: "", null: false
    t.string   "single_access_token", default: "", null: false
    t.string   "perishable_token",    default: "", null: false
    t.integer  "login_count",         default: 0,  null: false
    t.integer  "failed_login_count",  default: 0,  null: false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.string   "stripe_customer_id"
    t.integer  "roles_mask"
  end

end
