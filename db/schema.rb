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

ActiveRecord::Schema.define(version: 20150918122106) do

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

  create_table "campaigns", force: :cascade do |t|
    t.string   "type",                limit: 255
    t.integer  "property_id",         limit: 4
    t.integer  "user_id",             limit: 4
    t.integer  "template_id",         limit: 4
    t.string   "from",                limit: 255
    t.string   "subject",             limit: 255
    t.string   "reply_to",            limit: 255
    t.string   "cc",                  limit: 255
    t.string   "bcc",                 limit: 255
    t.text     "body_plain",          limit: 16777215
    t.text     "body_html",           limit: 16777215
    t.text     "body_text",           limit: 16777215
    t.text     "attachments",         limit: 65535
    t.text     "audience_ids",        limit: 65535
    t.text     "audience_counts",     limit: 65535
    t.boolean  "is_published",        limit: 1,        default: false, null: false
    t.datetime "published_at"
    t.integer  "sends_count",         limit: 4,        default: 0
    t.integer  "opens_count",         limit: 4,        default: 0
    t.integer  "unique_opens_count",  limit: 4,        default: 0
    t.integer  "clicks_count",        limit: 4,        default: 0
    t.integer  "unsubscribes_count",  limit: 4,        default: 0
    t.integer  "blacklisted_count",   limit: 4,        default: 0
    t.integer  "complaints_count",    limit: 4,        default: 0
    t.integer  "bounces_count",       limit: 4,        default: 0
    t.integer  "unique_clicks_count", limit: 4,        default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "campaigns", ["property_id", "created_at"], name: "index_campaigns_on__property_id_and_created_at", using: :btree
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
    t.integer  "author_id",   limit: 8
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
    t.string   "type",          limit: 255
    t.integer  "campaign_id",   limit: 4
    t.integer  "property_id",   limit: 4
    t.integer  "resident_id",   limit: 8
    t.integer  "url_id",        limit: 4
    t.string   "resolution",    limit: 255
    t.string   "browser",       limit: 255
    t.string   "os",            limit: 255
    t.string   "country",       limit: 255
    t.string   "ip",            limit: 255
    t.datetime "opened_at"
    t.integer  "response_time", limit: 4
    t.string   "mimepart",      limit: 255
    t.float    "executed_time", limit: 24,  default: 0.0
    t.string   "message_id",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "events", ["campaign_id", "created_at"], name: "index_events_on_campaign_id_and_created", using: :btree
  add_index "events", ["campaign_id", "opened_at"], name: "index_events_on_campaign_id_and_opened_at", using: :btree
  add_index "events", ["campaign_id", "resident_id"], name: "index_events_on_campaign_id_and_resident_id", using: :btree
  add_index "events", ["message_id"], name: "index_events_on_message_id", using: :btree
  add_index "events", ["mimepart"], name: "index_events_on_mimepart", using: :btree
  add_index "events", ["type", "campaign_id"], name: "index_events_on_type_and_campaign_id", using: :btree

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

  create_table "notification_histories", force: :cascade do |t|
    t.integer  "notification_id", limit: 4
    t.string   "state",           limit: 255
    t.integer  "actor_id",        limit: 4
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "notification_histories", ["notification_id", "state"], name: "index_notification_histories_on_notification_id_and_state", using: :btree

  create_table "notifications", force: :cascade do |t|
    t.integer  "property_id",   limit: 4
    t.integer  "resident_id",   limit: 8
    t.integer  "owner_id",      limit: 4
    t.string   "state",         limit: 255,   default: "pending"
    t.string   "subject",       limit: 255
    t.text     "message",       limit: 65535
    t.integer  "last_actor_id", limit: 4
    t.integer  "comment_id",    limit: 4
    t.datetime "deleted_at"
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "notifications", ["property_id", "resident_id"], name: "index_notifications_on_property_id_and_resident_id", using: :btree
  add_index "notifications", ["property_id", "state", "created_at"], name: "index_notifications_on_property_id_and_state_and_created_at", using: :btree

  create_table "properties", force: :cascade do |t|
    t.integer  "user_id",                   limit: 4
    t.integer  "region_id",                 limit: 4
    t.string   "name",                      limit: 255
    t.string   "address_line1",             limit: 255
    t.string   "address_line2",             limit: 255
    t.string   "city",                      limit: 255
    t.string   "state",                     limit: 255
    t.string   "zip",                       limit: 255
    t.string   "email",                     limit: 255
    t.string   "phone",                     limit: 255
    t.string   "webpage_url",               limit: 255
    t.string   "website_url",               limit: 255
    t.string   "status",                    limit: 255
    t.string   "regional_manager",          limit: 255
    t.string   "svp",                       limit: 255
    t.string   "property_number",           limit: 255
    t.string   "l2l_property_id",           limit: 255
    t.string   "yardi_property_id",         limit: 255
    t.string   "owner_group",               limit: 255
    t.datetime "date_opened"
    t.datetime "date_closed"
    t.string   "monday_open_time",          limit: 255
    t.string   "monday_close_time",         limit: 255
    t.string   "tuesday_open_time",         limit: 255
    t.string   "tuesday_close_time",        limit: 255
    t.string   "wednesday_open_time",       limit: 255
    t.string   "wednesday_close_time",      limit: 255
    t.string   "thursday_open_time",        limit: 255
    t.string   "thursday_close_time",       limit: 255
    t.string   "friday_open_time",          limit: 255
    t.string   "friday_close_time",         limit: 255
    t.string   "saturday_open_time",        limit: 255
    t.string   "saturday_close_time",       limit: 255
    t.string   "sunday_open_time",          limit: 255
    t.string   "sunday_close_time",         limit: 255
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
    t.boolean  "is_crm",                    limit: 1,     default: true
    t.string   "county",                    limit: 255
    t.text     "description",               limit: 65535
    t.text     "short_description",         limit: 65535
    t.float    "latitude",                  limit: 24
    t.float    "longitude",                 limit: 24
    t.float    "studio_price",              limit: 24
    t.boolean  "special_promotion",         limit: 1,     default: false
    t.string   "image_file_name",           limit: 255
    t.string   "image_content_type",        limit: 255
    t.integer  "image_file_size",           limit: 4
    t.datetime "image_updated_at"
    t.boolean  "studio",                    limit: 1,     default: false
    t.integer  "origin_id",                 limit: 4
    t.string   "bozzuto_url",               limit: 255
    t.string   "promotion_title",           limit: 255
    t.string   "promotion_subtitle",        limit: 255
    t.string   "promotion_url",             limit: 255
    t.date     "promotion_expiration_date"
    t.boolean  "is_smartrent",              limit: 1,     default: false
    t.boolean  "is_visible",                limit: 1,     default: true
    t.string   "updated_by",                limit: 255
  end

  add_index "properties", ["is_smartrent"], name: "index_properties_on_is_smartrent", using: :btree
  add_index "properties", ["name"], name: "index_properties_on_name", using: :btree
  add_index "properties", ["region_id"], name: "index_properties_on_region_id", using: :btree
  add_index "properties", ["user_id"], name: "index_properties_on_user_id", using: :btree

  create_table "property_settings", force: :cascade do |t|
    t.integer  "property_id",         limit: 4
    t.text     "notification_emails", limit: 65535
    t.string   "time_zone",           limit: 255
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "property_settings", ["property_id"], name: "index_property_settings_on_property_id", using: :btree

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

  create_table "smartrent_contacts", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "email",      limit: 255
    t.text     "message",    limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "smartrent_features", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "smartrent_floor_plan_images", force: :cascade do |t|
    t.string   "image_file_name",    limit: 255
    t.string   "image_content_type", limit: 255
    t.integer  "image_file_size",    limit: 4
    t.datetime "image_updated_at"
    t.string   "caption",            limit: 255
    t.integer  "more_home_id",       limit: 4
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "smartrent_floor_plan_images", ["more_home_id"], name: "index_smartrent_floor_plan_images_on_more_home_id", using: :btree

  create_table "smartrent_floor_plans", force: :cascade do |t|
    t.integer  "property_id", limit: 4
    t.integer  "origin_id",   limit: 4
    t.string   "name",        limit: 255
    t.string   "url",         limit: 255
    t.float    "sq_feet_max", limit: 24
    t.float    "sq_feet_min", limit: 24
    t.integer  "beds",        limit: 4
    t.integer  "baths",       limit: 4
    t.integer  "rent_min",    limit: 4
    t.integer  "rent_max",    limit: 4
    t.boolean  "penthouse",   limit: 1
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "smartrent_floor_plans", ["property_id"], name: "index_smartrent_floor_plans_on_property_id", using: :btree

  create_table "smartrent_homes", force: :cascade do |t|
    t.string   "title",                   limit: 255
    t.text     "address",                 limit: 65535
    t.string   "website",                 limit: 255
    t.text     "description",             limit: 65535
    t.float    "latitude",                limit: 24
    t.float    "longitude",               limit: 24
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "url",                     limit: 255
    t.string   "phone_number",            limit: 255
    t.string   "video_url",               limit: 255
    t.text     "home_page_desc",          limit: 65535
    t.string   "city",                    limit: 255
    t.string   "state",                   limit: 255
    t.string   "postal_code",             limit: 255
    t.string   "image_file_name",         limit: 255
    t.string   "image_content_type",      limit: 255
    t.integer  "image_file_size",         limit: 4
    t.datetime "image_updated_at"
    t.string   "image_description",       limit: 255
    t.text     "search_page_description", limit: 65535
  end

  create_table "smartrent_more_homes", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "beds",       limit: 4
    t.float    "baths",      limit: 24
    t.float    "sq_ft",      limit: 24
    t.boolean  "featured",   limit: 1
    t.integer  "home_id",    limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "smartrent_more_homes", ["home_id"], name: "index_smartrent_more_homes_on_home_id", using: :btree

  create_table "smartrent_property_features", force: :cascade do |t|
    t.integer  "feature_id",  limit: 4
    t.integer  "property_id", limit: 4
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "smartrent_property_features", ["feature_id"], name: "index_smartrent_property_features_on_feature_id", using: :btree
  add_index "smartrent_property_features", ["property_id"], name: "index_smartrent_property_features_on_property_id", using: :btree

  create_table "smartrent_resident_homes", force: :cascade do |t|
    t.integer  "resident_id", limit: 4
    t.integer  "home_id",     limit: 4
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "smartrent_resident_properties", force: :cascade do |t|
    t.integer  "resident_id",   limit: 4
    t.integer  "property_id",   limit: 4
    t.string   "status",        limit: 255
    t.date     "move_in_date"
    t.date     "move_out_date"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "smartrent_resident_properties", ["property_id"], name: "index_smartrent_resident_properties_on_property_id", using: :btree
  add_index "smartrent_resident_properties", ["resident_id"], name: "index_smartrent_resident_properties_on_resident_id", using: :btree
  add_index "smartrent_resident_properties", ["status"], name: "index_smartrent_resident_properties_on_status", using: :btree

  create_table "smartrent_residents", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",   null: false
    t.string   "encrypted_password",     limit: 255, default: "",   null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",        limit: 4,   default: 0,    null: false
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
    t.boolean  "active",                 limit: 1,   default: true
    t.integer  "crm_resident_id",        limit: 8
    t.string   "smartrent_status",       limit: 255
    t.datetime "expiry_date"
    t.datetime "champion_date"
    t.float    "champion_amount",        limit: 24,  default: 0.0
  end

  add_index "smartrent_residents", ["confirmation_token"], name: "index_smartrent_residents_on_confirmation_token", unique: true, using: :btree
  add_index "smartrent_residents", ["crm_resident_id"], name: "index_smartrent_residents_on_crm_resident_id", using: :btree
  add_index "smartrent_residents", ["email"], name: "index_smartrent_residents_on_email", unique: true, using: :btree
  add_index "smartrent_residents", ["reset_password_token"], name: "index_smartrent_residents_on_reset_password_token", unique: true, using: :btree

  create_table "smartrent_rewards", force: :cascade do |t|
    t.integer  "resident_id",   limit: 4
    t.integer  "type_",         limit: 4
    t.integer  "property_id",   limit: 4
    t.datetime "period_start"
    t.datetime "period_end"
    t.float    "amount",        limit: 24
    t.string   "rule_applied",  limit: 255
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "months_earned", limit: 4,   default: 0
  end

  add_index "smartrent_rewards", ["property_id"], name: "index_smartrent_rewards_on_property_id", using: :btree
  add_index "smartrent_rewards", ["resident_id"], name: "index_smartrent_rewards_on_resident_id", using: :btree

  create_table "smartrent_settings", force: :cascade do |t|
    t.string   "key",        limit: 255
    t.string   "value",      limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

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
    t.string   "updated_by",  limit: 255
    t.integer  "origin_id",   limit: 4
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

end
