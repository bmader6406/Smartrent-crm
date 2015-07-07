class CreateRecipients < ActiveRecord::Migration
  def change
    create_table :recipients do |t|
      t.integer  "campaign_id"
      t.integer  "audience_id"
      t.integer  "resident_id", :limit => 8
      t.string   "status"
      
      t.timestamps null: false
    end
    
    add_index "recipients", ["campaign_id", "resident_id", "audience_id"], :name => "index_recipients_on_campaign_resident_audience"
    add_index "recipients", ["campaign_id", "resident_id", "status"], :name => "index_recipients_on_campaign_resident_status"
    
  end
end
