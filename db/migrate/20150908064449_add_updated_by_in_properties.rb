class AddUpdatedByInProperties < ActiveRecord::Migration
  def change
    add_column :properties, :updated_by, :string
  end
end
