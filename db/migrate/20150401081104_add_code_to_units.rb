class AddCodeToUnits < ActiveRecord::Migration
  def change
    add_column :units, :code, :string
  end
end
