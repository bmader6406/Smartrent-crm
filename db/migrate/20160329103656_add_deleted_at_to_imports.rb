class AddDeletedAtToImports < ActiveRecord::Migration
  def change
    add_column :imports, :deleted_at, :datetime
    add_column :imports, :property_map, :text
  end
end
