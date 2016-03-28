class AddElanNumberToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :elan_number, :integer
    add_column :properties, :property_status, :string
  end
end
