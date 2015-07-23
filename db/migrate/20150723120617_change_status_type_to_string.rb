class ChangeStatusTypeToString < ActiveRecord::Migration
  def up
    change_column :smartrent_residents, :status,  :string
  end
  def down
    change_column :smartrent_residents, :status,  :integer
  end
end
