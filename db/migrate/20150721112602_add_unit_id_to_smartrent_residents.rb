class AddUnitIdToSmartrentResidents < ActiveRecord::Migration
  def change
    add_column :smartrent_residents, :unit_id, :string
    add_index "smartrent_residents", ["unit_id"]
  end
end
