class AddOriginIdToUnits < ActiveRecord::Migration
  def change
    add_column :units, :origin_id, :integer
  end
end
