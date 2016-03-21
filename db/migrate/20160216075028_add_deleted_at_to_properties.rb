class AddDeletedAtToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :deleted_at, :datetime
  end
end
