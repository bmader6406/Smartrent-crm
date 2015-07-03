class AddDeletedToUnits < ActiveRecord::Migration
  def change
    add_column :units, :deleted_at, :datetime
  end
end
