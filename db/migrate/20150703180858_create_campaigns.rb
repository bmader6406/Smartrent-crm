class CreateCampaigns < ActiveRecord::Migration
  def change
    create_table :campaigns do |t|
      t.integer  "property_id"
      t.text     "name"

      t.timestamps null: false
    end
    
    add_index "campaigns", ["property_id"], :name => "index_campaigns_on_property_id"
  end
end
