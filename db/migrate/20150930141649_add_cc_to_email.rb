class AddCcToEmail < ActiveRecord::Migration
  def change
    add_column :emails, :cc, :text
  end
end
