class CreateNewsletterTables < ActiveRecord::Migration
  def change
    create_table "templates" do |t|
      t.integer  "user_id"
      t.integer  "property_id"
      t.integer  "campaign_id"
      t.string   "name"
      
      t.datetime "deleted_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end


    add_index "templates", ["property_id"], :name => "index_templates_on_property_id"
    add_index "templates", ["campaign_id"], :name => "index_templates_on_campaign_id"
    
    create_table "campaigns" do |t|
      t.string   "type"
      t.integer  "property_id"
      t.integer  "user_id"
      t.integer  "template_id"
      
      t.string   "from"
      t.string   "subject"
      t.string   "reply_to"
      t.string   "cc"
      t.string   "bcc"
      t.text   "body_plain",      :limit => 16777215
      t.text   "body_html",      :limit => 16777215
      t.text   "body_text",      :limit => 16777215
      t.text   "attachments"
      t.text   "audience_ids"
      t.text     "audience_counts"
      
      t.boolean  "is_published",                                    :default => false,     :null => false
      t.datetime "published_at"
      t.integer  "sends_count",                                     :default => 0
      t.integer  "opens_count",                                     :default => 0
      t.integer  "unique_opens_count",                              :default => 0
      t.integer  "clicks_count",                                    :default => 0
      t.integer  "unsubscribes_count",                              :default => 0
      t.integer  "blacklisted_count",                               :default => 0
      t.integer  "complaints_count",                                :default => 0
      t.integer  "bounces_count",                                   :default => 0
      t.integer  "unique_clicks_count",                             :default => 0
      
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "deleted_at"
    end

    add_index "campaigns", ["user_id"], :name => "index_campaigns_on_user_id"
    add_index "campaigns", ["property_id", "created_at"], :name => "index_campaigns_on__property_id_and_created_at"
    
    create_table "audiences" do |t|
      t.string   "type"
      t.integer  "property_id"
      t.string   "name"
      t.text     "description"
      t.text     "expression"
      t.string   "lead_type"

      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "audiences", ["property_id"], :name => "index_audiences_on_property_id"


    create_table "events" do |t|
      t.string   "type"
      t.integer  "campaign_id"
      t.integer  "property_id"
      t.integer  "resident_id", :limit => 8
      t.integer  "url_id"
      t.string   "resolution"
      t.string   "browser"
      t.string   "os"
      t.string   "country"
      t.string   "ip"
      t.datetime "opened_at"
      t.integer  "response_time"
      t.string   "mimepart"
      t.float    "executed_time",                      :default => 0.0
      t.string   "message_id"

      t.datetime "created_at"
      t.datetime "updated_at"
    end


    add_index "events", ["type", "campaign_id"], :name => "index_events_on_type_and_campaign_id"
    add_index "events", ["campaign_id", "created_at"], :name => "index_events_on_campaign_id_and_created"
    add_index "events", ["campaign_id", "resident_id"], :name => "index_events_on_campaign_id_and_resident_id"
    add_index "events", ["campaign_id", "opened_at"], :name => "index_events_on_campaign_id_and_opened_at"
    add_index "events", ["message_id"], :name => "index_events_on_message_id"
    add_index "events", ["mimepart"], :name => "index_events_on_mimepart"

    create_table "monitor_metrics" do |t|
      t.integer  "total"
      t.string   "source",           :default => "email_forwarding"
      t.integer  "bounces_count"
      t.text     "bounces"
      t.integer  "complaints_count"
      t.text     "complaints"
      t.integer  "errors_count"
      t.text     "error_details"
      
      t.datetime "created_at",                                       :null => false
      t.datetime "updated_at",                                       :null => false
    end
    
    add_index "monitor_metrics", ["created_at"], :name => "index_monitor_metrics_on_created_at"

    create_table "actions" do |t|
      t.string   "type"
      t.integer  "user_id"
      t.integer  "actor_id"
      t.integer  "subject_id"
      t.string   "subject_type"
      t.string   "options"
      t.string   "error"
      t.integer  "attempt"
      t.datetime "execute_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "urls", :force => true do |t|
      t.integer  "campaign_id"
      t.string   "token"
      t.text     "origin_url"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "urls", ["campaign_id"], :name => "index_urls_on_campaign_id"
    add_index "urls", ["token"], :name => "index_urls_on_token"

  end
end
