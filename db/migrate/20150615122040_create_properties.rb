class CreateProperties < ActiveRecord::Migration
  def up
    create_table :properties do |t|
      t.integer  :user_id
      t.integer  :region_id
      
      t.string :name
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :zip
      t.string :region
      t.string :email
      t.string :phone
      t.string :webpage_url
      t.string :website_url
      t.string :status
      t.string :regional_manager
      t.string :svp
      t.string :property_number
      t.string :l2l_property_id
      t.string :yardi_property_id
      t.string :owner_group
      t.datetime :date_opened
      t.datetime :date_closed
      t.string :monday_open_time
      t.string :monday_close_time
      t.string :tuesday_open_time
      t.string :tuesday_close_time
      t.string :wednesday_open_time
      t.string :wednesday_close_time
      t.string :thursday_open_time
      t.string :thursday_close_time
      t.string :friday_open_time
      t.string :friday_close_time
      t.string :saturday_open_time
      t.string :saturday_close_time
      t.string :sunday_open_time
      t.string :sunday_close_time
      
      t.timestamps null: false
    end
    
    add_index "properties", ["name"]
    add_index "properties", ["user_id"]
    add_index "properties", ["region_id"]
  end
  
  def down
    drop_table :properties
  end
end
