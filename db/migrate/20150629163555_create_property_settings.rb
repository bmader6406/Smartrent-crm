class CreatePropertySettings < ActiveRecord::Migration
  def up
    create_table :property_settings do |t|
      t.integer  "property_id"
      t.text     "notification_emails"
      t.string   "time_zone"
      t.text     "ftp_setting",          :limit => 16777215
      t.text     "universal_recipients"
      t.boolean  "bcc_responder",                            :default => false

      t.timestamps null: false
    end
    
    add_index "property_settings", ["property_id"], :name => "index_property_settings_on_property_id"
    
  end
  
  def down
    drop_table :property_settings
  end
end