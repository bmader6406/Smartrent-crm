class CreateAudiences < ActiveRecord::Migration
  def change
    create_table :audiences do |t|
      t.integer  "property_id"
      t.text     "name"
      t.string   "resident_type"

      t.timestamps null: false
    end
    
    add_index "audiences", ["property_id"], :name => "index_audiences_on_property_id"
  end
end
