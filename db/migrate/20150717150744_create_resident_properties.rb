class CreateResidentProperties < ActiveRecord::Migration
  def change
    create_table :smartrent_resident_properties do |t|
      t.integer :resident_id
      t.integer :property_id
      t.integer :house_hold_size
      t.integer :pets_count
      t.date :contract_signing_date
      t.string :status
      t.date :move_in_date
      t.date :move_out_date

      t.timestamps null: false
    end
    add_index "smartrent_resident_properties", ["resident_id"]
    add_index "smartrent_resident_properties", ["property_id"]
    add_index "smartrent_resident_properties", ["status"]
    #Propeties
    add_index "properties", ["is_smartrent"]
    #Smartrent Residents
    add_index "smartrent_residents", ["crm_resident_id"]
  end
end
