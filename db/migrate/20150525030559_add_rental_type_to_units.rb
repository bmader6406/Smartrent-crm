class AddRentalTypeToUnits < ActiveRecord::Migration
  def change
    add_column :units, :rental_type, :string
  end
end
