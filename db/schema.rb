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

ActiveRecord::Schema.define(version: 20150707101036) do

  create_table "actions", force: :cascade do |t|
    t.string   "type",         limit: 255
    t.integer  "user_id",      limit: 4
    t.integer  "actor_id",     limit: 4
    t.integer  "subject_id",   limit: 4
    t.string   "subject_type", limit: 255
    t.string   "options",      limit: 255
    t.string   "error",        limit: 255
    t.integer  "attempt",      limit: 4
    t.datetime "execute_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assets", force: :cascade do |t|
    t.integer  "comment_id",        limit: 4
    t.string   "type",              limit: 255
    t.string   "file_file_name",    limit: 255
    t.string   "file_content_type", limit: 255
    t.integer  "file_file_size",    limit: 4
    t.datetime "file_updated_at"
    t.string   "dimensions",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "property_id",       limit: 4
    t.integer  "ticket_id",         limit: 4
    t.string   "location",          limit: 255
  end

  add_index "assets", ["comment_id"], name: "index_assets_on_comment_id", using: :btree
  add_index "assets", ["property_id"], name: "index_assets_on_property_id", using: :btree
  add_index "assets", ["ticket_id"], name: "index_assets_on_ticket_id", using: :btree

  create_table "audiences", force: :cascade do |t|
    t.string   "type",        limit: 255
    t.integer  "property_id", limit: 4
    t.string   "name",        limit: 255
    t.text     "description", limit: 65535
    t.text     "expression",  limit: 65535
    t.string   "lead_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "audiences", ["property_id"], name: "index_audiences_on_property_id", using: :btree

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

  create_table "calls", force: :cascade do |t|
    t.integer  "comment_id",         limit: 4
    t.string   "from",               limit: 255
    t.string   "to",                 limit: 255
    t.integer  "recording_duration", limit: 4,   default: 0
    t.string   "recording_url",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "origin_id",          limit: 255
  end

  add_index "calls", ["comment_id"], name: "index_calls_on_comment_id", using: :btree
  add_index "calls", ["origin_id"], name: "index_calls_on_origin_id", using: :btree

  create_table "campaign_variations", force: :cascade do |t|
    t.string   "type",                limit: 255
    t.integer  "campaign_id",         limit: 4
    t.integer  "variate_campaign_id", limit: 4
    t.integer  "weight",              limit: 4,   default: 1
    t.integer  "weight_percent",      limit: 4,   default: 0
    t.boolean  "can_delete",          limit: 1,   default: true
    t.integer  "channel",             limit: 4,   default: 0
    t.string   "channel_name",        limit: 255
    t.string   "version",             limit: 255, default: "0"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "campaign_variations", ["campaign_id"], name: "index_campaign_variations_on_campaign_id", using: :btree

  create_table "campaigns", force: :cascade do |t|
    t.string   "type",                        limit: 255
    t.string   "annotation",                  limit: 255
    t.integer  "property_id",                 limit: 4
    t.integer  "user_id",                     limit: 4
    t.integer  "parent_id",                   limit: 4
    t.integer  "root_id",                     limit: 4
    t.integer  "group_id",                    limit: 4
    t.integer  "template_id",                 limit: 4
    t.text     "audience_counts",             limit: 65535
    t.boolean  "is_published",                limit: 1,     default: false, null: false
    t.datetime "published_at"
    t.integer  "sends_count",                 limit: 4,     default: 0
    t.integer  "variant_sends_count",         limit: 4,     default: 0
    t.integer  "opens_count",                 limit: 4,     default: 0
    t.integer  "variant_opens_count",         limit: 4,     default: 0
    t.integer  "unique_opens_count",          limit: 4,     default: 0
    t.integer  "variant_unique_opens_count",  limit: 4,     default: 0
    t.integer  "clicks_count",                limit: 4,     default: 0
    t.integer  "variant_clicks_count",        limit: 4,     default: 0
    t.integer  "unsubscribes_count",          limit: 4,     default: 0
    t.integer  "variant_unsubscribes_count",  limit: 4,     default: 0
    t.integer  "blacklisted_count",           limit: 4,     default: 0
    t.integer  "variant_blacklisted_count",   limit: 4,     default: 0
    t.integer  "complaints_count",            limit: 4,     default: 0
    t.integer  "variant_complaints_count",    limit: 4,     default: 0
    t.integer  "bounces_count",               limit: 4,     default: 0
    t.integer  "variant_bounces_count",       limit: 4,     default: 0
    t.integer  "unique_clicks_count",         limit: 4,     default: 0
    t.integer  "variant_unique_clicks_count", limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "campaigns", ["group_id"], name: "index_campaigns_on_group_id", using: :btree
  add_index "campaigns", ["parent_id"], name: "index_campaigns_on_parent_id", using: :btree
  add_index "campaigns", ["property_id", "created_at"], name: "index_campaigns_on__property_id_and_created_at", using: :btree
  add_index "campaigns", ["root_id"], name: "index_campaigns_on_root_id", using: :btree
  add_index "campaigns", ["user_id"], name: "index_campaigns_on_user_id", using: :btree

  create_table "categories", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "abbr",       limit: 255
    t.integer  "position",   limit: 4,   default: 0
    t.boolean  "active",     limit: 1,   default: true
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", force: :cascade do |t|
    t.integer  "property_id", limit: 4
    t.integer  "resident_id", limit: 8
    t.string   "type",        limit: 255
    t.text     "message",     limit: 65535
    t.string   "ancestry",    limit: 255
    t.integer  "author_id",   limit: 4
    t.string   "author_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "comments", ["ancestry"], name: "index_comments_on_ancestry", using: :btree
  add_index "comments", ["property_id"], name: "index_comments_on_property_id", using: :btree

  create_table "emails", force: :cascade do |t|
    t.integer  "comment_id", limit: 4
    t.string   "subject",    limit: 255
    t.string   "from",       limit: 255
    t.string   "to",         limit: 255
    t.text     "message",    limit: 65535
    t.string   "token",      limit: 255
    t.string   "message_id", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "emails", ["comment_id"], name: "index_emails_on_comment_id", using: :btree
  add_index "emails", ["token"], name: "index_emails_on_token", using: :btree

  create_table "events", force: :cascade do |t|
    t.string   "type",                  limit: 255
    t.integer  "campaign_id",           limit: 4
    t.integer  "property_id",           limit: 4
    t.integer  "campaign_variation_id", limit: 4
    t.integer  "resident_id",           limit: 8
    t.integer  "url_id",                limit: 4
    t.string   "resolution",            limit: 255
    t.string   "browser",               limit: 255
    t.string   "os",                    limit: 255
    t.string   "country",               limit: 255
    t.string   "ip",                    limit: 255
    t.datetime "opened_at"
    t.integer  "response_time",         limit: 4
    t.string   "mimepart",              limit: 255
    t.float    "executed_time",         limit: 24,  default: 0.0
    t.string   "message_id",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "events", ["campaign_id", "created_at"], name: "index_events_on_campaign_id_and_created", using: :btree
  add_index "events", ["campaign_id", "opened_at"], name: "index_events_on_campaign_id_and_opened_at", using: :btree
  add_index "events", ["campaign_id", "resident_id"], name: "index_events_on_campaign_id_and_resident_id", using: :btree
  add_index "events", ["message_id"], name: "index_events_on_message_id", using: :btree
  add_index "events", ["mimepart"], name: "index_events_on_mimepart", using: :btree
  add_index "events", ["type", "campaign_id"], name: "index_events_on_type_and_campaign_id", using: :btree

  create_table "hylets", force: :cascade do |t|
    t.string   "type",        limit: 255
    t.integer  "property_id", limit: 4
    t.integer  "campaign_id", limit: 4
    t.string   "title1",      limit: 255
    t.text     "text1",       limit: 16777215
    t.text     "style1",      limit: 65535
    t.integer  "value1",      limit: 4,        default: 0
    t.boolean  "flag1",       limit: 1,        default: false
    t.string   "title2",      limit: 255
    t.text     "text2",       limit: 16777215
    t.text     "style2",      limit: 65535
    t.integer  "value2",      limit: 4,        default: 0
    t.boolean  "flag2",       limit: 1,        default: false
    t.string   "title3",      limit: 255
    t.text     "text3",       limit: 16777215
    t.text     "style3",      limit: 65535
    t.integer  "value3",      limit: 4,        default: 0
    t.boolean  "flag3",       limit: 1,        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "hylets", ["campaign_id", "type"], name: "index_hylets_on_campaign_id_and_type", using: :btree
  add_index "hylets", ["property_id", "type"], name: "index_hylets_on_property_id_and_type", using: :btree

  create_table "invites", force: :cascade do |t|
    t.string   "email",       limit: 255
    t.string   "token",       limit: 255
    t.string   "target_type", limit: 255
    t.integer  "target_id",   limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "invites", ["token"], name: "index_invites_on_token", using: :btree

  create_table "monitor_metrics", force: :cascade do |t|
    t.integer  "total",            limit: 4
    t.string   "source",           limit: 255,   default: "email_forwarding"
    t.integer  "bounces_count",    limit: 4
    t.text     "bounces",          limit: 65535
    t.integer  "complaints_count", limit: 4
    t.text     "complaints",       limit: 65535
    t.integer  "errors_count",     limit: 4
    t.text     "error_details",    limit: 65535
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
  end

  add_index "monitor_metrics", ["created_at"], name: "index_monitor_metrics_on_created_at", using: :btree

  create_table "properties", force: :cascade do |t|
    t.integer  "user_id",              limit: 4
    t.integer  "region_id",            limit: 4
    t.string   "name",                 limit: 255
    t.string   "address_line1",        limit: 255
    t.string   "address_line2",        limit: 255
    t.string   "city",                 limit: 255
    t.string   "state",                limit: 255
    t.string   "zip",                  limit: 255
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
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
  end

  add_index "property_settings", ["property_id"], name: "index_property_settings_on_property_id", using: :btree

  create_table "recipients", force: :cascade do |t|
    t.integer  "campaign_id", limit: 4
    t.integer  "audience_id", limit: 4
    t.integer  "resident_id", limit: 8
    t.string   "status",      limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "recipients", ["campaign_id", "resident_id", "audience_id"], name: "index_recipients_on_campaign_resident_audience", using: :btree
  add_index "recipients", ["campaign_id", "resident_id", "status"], name: "index_recipients_on_campaign_resident_status", using: :btree

  create_table "regions", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "resident_metrics", force: :cascade do |t|
    t.integer  "property_id", limit: 4
    t.string   "type",        limit: 255
    t.string   "status",      limit: 255
    t.string   "rental_type", limit: 255
    t.string   "dimension",   limit: 255
    t.integer  "total",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resident_metrics", ["property_id", "type"], name: "index_resident_metrics_on_property_id_and_type", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.string   "resource_type", limit: 255
    t.integer  "resource_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "suppression_emails", force: :cascade do |t|
    t.string   "email",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "suppression_emails", ["email"], name: "index_suppression_emails_on_email", using: :btree

  create_table "templates", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.integer  "property_id", limit: 4
    t.integer  "campaign_id", limit: 4
    t.string   "name",        limit: 255
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "templates", ["campaign_id"], name: "index_templates_on_campaign_id", using: :btree
  add_index "templates", ["property_id"], name: "index_templates_on_property_id", using: :btree

  create_table "tickets", force: :cascade do |t|
    t.integer  "property_id",       limit: 4
    t.integer  "resident_id",       limit: 8
    t.string   "title",             limit: 255
    t.text     "description",       limit: 65535
    t.string   "status",            limit: 255
    t.string   "urgency",           limit: 255
    t.integer  "category_id",       limit: 4
    t.integer  "assigner_id",       limit: 4
    t.integer  "assignee_id",       limit: 4
    t.boolean  "can_enter",         limit: 1,     default: false
    t.string   "entry_instruction", limit: 255
    t.string   "additional_emails", limit: 255
    t.string   "additional_phones", limit: 255
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tickets", ["property_id"], name: "index_tickets_on_property_id", using: :btree

  create_table "units", force: :cascade do |t|
    t.integer  "property_id", limit: 4
    t.integer  "bed",         limit: 4
    t.integer  "bath",        limit: 4
    t.float    "sq_ft",       limit: 24
    t.string   "status",      limit: 255
    t.text     "description", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "code",        limit: 255
    t.datetime "deleted_at"
    t.string   "rental_type", limit: 255
  end

  add_index "units", ["property_id"], name: "index_units_on_property_id", using: :btree

  create_table "urls", force: :cascade do |t|
    t.integer  "campaign_id", limit: 4
    t.string   "token",       limit: 255
    t.text     "origin_url",  limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "urls", ["campaign_id"], name: "index_urls_on_campaign_id", using: :btree
  add_index "urls", ["token"], name: "index_urls_on_token", using: :btree

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

  create_table "variation_metrics", force: :cascade do |t|
    t.integer  "campaign_id",         limit: 4
    t.integer  "variation_id",        limit: 4
    t.string   "type",                limit: 255
    t.string   "text",                limit: 255
    t.integer  "property_id",         limit: 4
    t.integer  "sends_count",         limit: 4,   default: 0
    t.integer  "opens_count",         limit: 4,   default: 0
    t.integer  "unique_opens_count",  limit: 4,   default: 0
    t.integer  "unsubscribes_count",  limit: 4,   default: 0
    t.integer  "clicks_count",        limit: 4,   default: 0
    t.integer  "blacklisted_count",   limit: 4,   default: 0
    t.integer  "complaints_count",    limit: 4,   default: 0
    t.integer  "bounces_count",       limit: 4,   default: 0
    t.integer  "events_count",        limit: 4,   default: 0
    t.integer  "unique_clicks_count", limit: 4,   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "variation_metrics", ["campaign_id", "type", "created_at"], name: "index_variation_metrics_on_campaign_id_and_type_and_created_at", using: :btree
  add_index "variation_metrics", ["campaign_id"], name: "index_variation_metrics_on_campaign_id", using: :btree
  add_index "variation_metrics", ["property_id", "type", "created_at"], name: "index_vm_on_property_and_type_and_ca", using: :btree
  add_index "variation_metrics", ["property_id", "variation_id", "type"], name: "index_vm_on_property_and_variation_and_type", using: :btree

end
