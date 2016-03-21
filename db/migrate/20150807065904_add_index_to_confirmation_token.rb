class AddIndexToConfirmationToken < ActiveRecord::Migration
  def up
    add_index :smartrent_residents, :confirmation_token, :unique => true
  end
  def down
    remove_index :smartrent_residents, :confirmation_token
  end
end
