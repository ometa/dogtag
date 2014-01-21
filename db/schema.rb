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

ActiveRecord::Schema.define(version: 20140121042043) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "completed_requirements", force: true do |t|
    t.integer  "registration_id"
    t.integer  "requirement_id"
    t.integer  "user_id"
    t.text     "metadata"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "completed_requirements", ["registration_id", "requirement_id"], name: "completed_requirements_index", unique: true, using: :btree

  create_table "people", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "phone"
    t.string   "twitter"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "registration_id"
    t.integer  "experience"
  end

  create_table "races", force: true do |t|
    t.string   "name"
    t.datetime "race_datetime"
    t.datetime "registration_open"
    t.datetime "registration_close"
    t.integer  "max_teams"
    t.integer  "people_per_team"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "registrations", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "twitter"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "notified_at"
    t.integer  "team_id"
    t.integer  "race_id"
    t.string   "racer_type"
    t.string   "primary_inspiration"
    t.boolean  "rules_confirmation"
    t.boolean  "sabotage_confirmation"
    t.boolean  "cart_deposit_confirmation"
    t.boolean  "food_confirmation"
    t.integer  "experience"
    t.string   "buddies"
    t.string   "wildcard"
    t.text     "private_comments"
  end

  add_index "registrations", ["team_id", "race_id"], name: "index_registrations_on_team_id_and_race_id", unique: true, using: :btree

  create_table "requirements", force: true do |t|
    t.integer  "race_id"
    t.string   "type"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "teams", force: true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tiers", force: true do |t|
    t.integer  "requirement_id"
    t.datetime "begin_at"
    t.integer  "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
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
