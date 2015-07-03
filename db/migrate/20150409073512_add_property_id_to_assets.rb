class AddPropertyIdToAssets < ActiveRecord::Migration
  def change
    add_column :assets, :property_id, :integer
    add_column :assets, :ticket_id, :integer
    add_column :assets, :location, :string
    
    add_index "assets", ["property_id"]
    add_index "assets", ["ticket_id"]
  end
end
