class AddOriginIdToCalls < ActiveRecord::Migration
  def change
    add_column :calls, :origin_id, :string
  end
end
