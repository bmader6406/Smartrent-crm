class AddSmartrentStatusToSmartrentResidents < ActiveRecord::Migration
  def change
    add_column :smartrent_residents, :smartrent_status, :string
  end
end
