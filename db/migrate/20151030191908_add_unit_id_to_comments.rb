class AddUnitIdToComments < ActiveRecord::Migration
  def change
    add_column :comments, :unit_id, :integer
    add_column :tickets, :unit_id, :integer
    add_column :notifications, :unit_id, :integer
  end
end
