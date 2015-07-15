class AddIsCrmFieldToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :is_crm, :boolean, :default => true
  end
end
