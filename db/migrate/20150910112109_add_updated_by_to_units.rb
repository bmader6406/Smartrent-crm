class AddUpdatedByToUnits < ActiveRecord::Migration
  def change
    add_column :units, :updated_by, :string
  end
end
