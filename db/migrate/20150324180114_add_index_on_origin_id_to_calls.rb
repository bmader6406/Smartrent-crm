class AddIndexOnOriginIdToCalls < ActiveRecord::Migration
  def change
    add_index "calls", ["origin_id"]
  end
end
