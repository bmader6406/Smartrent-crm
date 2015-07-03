class CreateInvites < ActiveRecord::Migration
  def up
    create_table :invites do |t|
      t.string :email
      t.string :token
      t.string   :target_type
      t.integer  :target_id
      
      t.timestamps null: false
    end
    
    add_index "invites", ["token"]
  end
  
  def down
    drop_table :invites
  end
end
