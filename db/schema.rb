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

ActiveRecord::Schema.define(version: 20150629163555) do

  create_table "authentications", force: :cascade do |t|
    t.integer  "user_id",          limit: 4
    t.string   "provider",         limit: 255
    t.string   "uid",              limit: 255
    t.string   "name",             limit: 255
    t.string   "oauth_token",      limit: 255
    t.string   "oauth_secret",     limit: 255
    t.datetime "oauth_expires_at"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "authentications", ["user_id"], name: "index_authentications_on_user_id", using: :btree

  create_table "invites", force: :cascade do |t|
    t.string   "email",       limit: 255
    t.string   "token",       limit: 255
    t.string   "target_type", limit: 255
    t.integer  "target_id",   limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "invites", ["token"], name: "index_invites_on_token", using: :btree

  create_table "properties", force: :cascade do |t|
    t.integer  "user_id",              limit: 4
    t.integer  "region_id",            limit: 4
    t.string   "name",                 limit: 255
    t.string   "address_line1",        limit: 255
    t.string   "address_line2",        limit: 255
    t.string   "city",                 limit: 255
    t.string   "state",                limit: 255
    t.string   "zip",                  limit: 255
    t.string   "region",               limit: 255
    t.string   "email",                limit: 255
    t.string   "phone",                limit: 255
    t.string   "webpage_url",          limit: 255
    t.string   "website_url",          limit: 255
    t.string   "status",               limit: 255
    t.string   "regional_manager",     limit: 255
    t.string   "svp",                  limit: 255
    t.string   "property_number",      limit: 255
    t.string   "l2l_property_id",      limit: 255
    t.string   "yardi_property_id",    limit: 255
    t.string   "owner_group",          limit: 255
    t.datetime "date_opened"
    t.datetime "date_closed"
    t.string   "monday_open_time",     limit: 255
    t.string   "monday_close_time",    limit: 255
    t.string   "tuesday_open_time",    limit: 255
    t.string   "tuesday_close_time",   limit: 255
    t.string   "wednesday_open_time",  limit: 255
    t.string   "wednesday_close_time", limit: 255
    t.string   "thursday_open_time",   limit: 255
    t.string   "thursday_close_time",  limit: 255
    t.string   "friday_open_time",     limit: 255
    t.string   "friday_close_time",    limit: 255
    t.string   "saturday_open_time",   limit: 255
    t.string   "saturday_close_time",  limit: 255
    t.string   "sunday_open_time",     limit: 255
    t.string   "sunday_close_time",    limit: 255
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "properties", ["name"], name: "index_properties_on_name", using: :btree
  add_index "properties", ["region_id"], name: "index_properties_on_region_id", using: :btree
  add_index "properties", ["user_id"], name: "index_properties_on_user_id", using: :btree

  create_table "property_settings", force: :cascade do |t|
    t.integer  "property_id",          limit: 4
    t.text     "notification_emails",  limit: 65535
    t.string   "time_zone",            limit: 255
    t.text     "ftp_setting",          limit: 16777215
    t.text     "universal_recipients", limit: 65535
    t.boolean  "bcc_responder",        limit: 1,        default: false
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
  end

  add_index "property_settings", ["property_id"], name: "index_property_settings_on_property_id", using: :btree

  create_table "regions", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.string   "resource_type", limit: 255
    t.integer  "resource_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",             limit: 255
    t.string   "last_name",         limit: 255
    t.string   "first_name",        limit: 255
    t.string   "time_zone",         limit: 255
    t.string   "address1",          limit: 255
    t.string   "address2",          limit: 255
    t.string   "city",              limit: 255
    t.string   "state",             limit: 255
    t.string   "zip",               limit: 255
    t.string   "country",           limit: 255
    t.string   "phone",             limit: 255
    t.string   "referer",           limit: 255
    t.string   "avatar_url",        limit: 255
    t.boolean  "active",            limit: 1,   default: true
    t.string   "crypted_password",  limit: 255
    t.string   "password_salt",     limit: 255
    t.string   "persistence_token", limit: 255
    t.string   "perishable_token",  limit: 255
    t.integer  "login_count",       limit: 4,   default: 0,    null: false
    t.datetime "last_request_at"
    t.datetime "last_login_at"
    t.datetime "current_login_at"
    t.string   "last_login_ip",     limit: 255
    t.string   "current_login_ip",  limit: 255
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["last_request_at"], name: "index_users_on_last_request_at", using: :btree
  add_index "users", ["persistence_token"], name: "index_users_on_persistence_token", using: :btree

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id", limit: 4
    t.integer "role_id", limit: 4
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

end
