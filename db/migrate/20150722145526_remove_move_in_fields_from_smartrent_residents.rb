class RemoveMoveInFieldsFromSmartrentResidents < ActiveRecord::Migration
  def up
    remove_column :smartrent_residents, :move_in_date
    remove_column :smartrent_residents, :move_out_date
  end
  def down
    add_column :smartrent_residents, :move_in_date, :date
    add_column :smartrent_residents, :move_out_date, :date
  end
end
