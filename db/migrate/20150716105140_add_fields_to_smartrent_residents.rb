class AddFieldsToSmartrentResidents < ActiveRecord::Migration
  def change
    add_column :smartrent_residents, :crm_resident_id, :integer, :limit => 8
  end
end
