class AddIsVisibleColumnToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :is_visible, :boolean, :default => true
  end
end
