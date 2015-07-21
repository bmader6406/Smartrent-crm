class RemoveFieldsFromSmartrentResidents < ActiveRecord::Migration
  def up
    remove_column :smartrent_residents, :property_id
    remove_column :smartrent_residents, :home_id
    remove_column :smartrent_residents, :house_hold_size
    remove_column :smartrent_residents, :pets_count
  end
  def down
    add_column :smartrent_residents, :property_id, :integer
    add_column :smartrent_residents, :home_id, :integer
    add_column :smartrent_residents, :house_hold_size, :integer
    add_column :smartrent_residents, :pets_count, :integer
  end
end
